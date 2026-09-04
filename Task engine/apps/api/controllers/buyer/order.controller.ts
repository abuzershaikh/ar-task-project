import {
    Controller,
    Get,
    Post,
    Param,
    Body,
    NotFoundException,
    BadRequestException,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { OrderRepository } from '../../../../shared/database/repositories/order.repository';
import { TaskRepository } from '../../../../shared/database/repositories/task.repository';
import { SubmissionRepository } from '../../../../shared/database/repositories/submission.repository';
import { ServiceCatalogRepository } from '../../../../shared/database/repositories/service-catalog.repository';
import { TaskEngineService } from '../../../../task-engine/task-engine.service';
import { ProgressEngineService } from '../../../../progress-engine/progress.service';
import { PricingEngine } from '../../../../shared/engines/pricing-engine/pricing.engine';
import { CurrentUser } from '../../../../shared/auth/decorators/current-user.decorator';
import { Roles } from '../../../../shared/auth/decorators/roles.decorator';
import { UserRole, User } from '../../../../shared/database/entities/user.entity';
import { TimingPolicy } from '../../../../shared/policies/timing-policy';
import { WalletService } from '../../../../shared/services/wallet.service';
import { AiGeneratorService } from '../../../../shared/ai-generator/ai-generator.service';
import { EventEmitter2 } from '@nestjs/event-emitter';

@ApiTags('Buyer - Orders')
@Roles(UserRole.BUYER)
@ApiBearerAuth('bearer')
@Controller('buyer/orders')
export class BuyerOrderController {
    constructor(
        private readonly orderRepo: OrderRepository,
        private readonly taskRepo: TaskRepository,
        private readonly submissionRepo: SubmissionRepository,
        private readonly serviceCatalogRepo: ServiceCatalogRepository,
        private readonly taskEngine: TaskEngineService,
        private readonly progressEngine: ProgressEngineService,
        private readonly pricingEngine: PricingEngine,
        private readonly walletService: WalletService,
        private readonly aiGeneratorService: AiGeneratorService,
        private readonly eventEmitter: EventEmitter2,
    ) { }

    @Post('ai-preview-comments')
    @ApiOperation({ summary: 'Generate 5 sample comments preview using DeepSeek AI' })
    async previewAiComments(
        @Body() body: {
            topic?: string;
            language?: string;
            tone?: string;
            count?: number;
            serviceCode?: string;
            targetUrl?: string;
        },
    ) {
        const topic = body.topic?.trim() || '';
        const language = body.language || 'English';
        const tone = body.tone || 'natural';
        const requestedTotal = body.count || 10;
        const previewCount = Math.min(5, requestedTotal > 0 ? requestedTotal : 5);

        const serviceCode = (body.serviceCode || '').toLowerCase();
        const isPlayStore = serviceCode.includes('play') || serviceCode.includes('review') || serviceCode.includes('rating') || serviceCode.includes('app');
        const generatorType = isPlayStore ? 'playstore_review' : 'youtube_comment';

        const sampleComments = await this.aiGeneratorService.generateContentBatch(
            generatorType,
            previewCount,
            { topic, language, tone, uniqueness: true, videoTitle: body.targetUrl, isAppReview: isPlayStore, generatorType } as any,
        );

        return {
            success: true,
            sampleComments,
            totalRequested: requestedTotal,
            previewCount: sampleComments.length,
            remainingToGenerate: Math.max(0, requestedTotal - sampleComments.length),
            message: `Generated ${sampleComments.length} sample comments via DeepSeek AI. Remaining comments will be generated upon order placement.`,
        };
    }

    @Get('price-estimate')
    @ApiOperation({ summary: 'Get server-calculated price estimate for buyer (Display-only preview)' })
    async getPriceEstimate(
        @Body() body: { serviceId?: string; serviceCode?: string; quantity: number },
    ) {
        const identifier = body.serviceId || body.serviceCode;
        if (!identifier) {
            throw new BadRequestException('serviceId or serviceCode is required');
        }

        const estimate = await this.pricingEngine.calculateBuyerPrice(identifier, body.quantity);
        return {
            success: true,
            estimate,
        };
    }

    @Post()
    @ApiOperation({ summary: 'Create a new campaign order with server-calculated price snapshot' })
    async createOrder(
        @CurrentUser() user: User,
        @Body()
        data: {
            title?: string;
            description?: string;
            serviceId?: string;
            serviceCode?: string;
            taskType?: string;
            quantity?: number;
            totalTasksRequired?: number;
            requirements?: any;
            reviewMode?: string;
            timeToAcceptHours?: number;
            timeToCompleteHours?: number;
            campaignExpiryDate?: string;
        },
    ) {
        const serviceIdentifier = data.serviceId || data.serviceCode || data.taskType;
        const quantity = data.quantity || data.totalTasksRequired;

        if (!serviceIdentifier || !quantity) {
            throw new BadRequestException('serviceId/serviceCode and quantity are required');
        }

        let snapshot: any = null;
        try {
            snapshot = await this.pricingEngine.createOrderPriceSnapshot(serviceIdentifier, quantity);
        } catch (error) {
            throw new BadRequestException(
                `Cannot create order: Pricing is not available for service '${serviceIdentifier}'. Please ensure the service has active pricing configured. Detail: ${error.message}`
            );
        }

        // Fetch Service Catalog to inherit reviewMode and potentially validate elements
        let catalog = await this.serviceCatalogRepo.findById(serviceIdentifier);
        if (!catalog) {
            catalog = await this.serviceCatalogRepo.findByCode(serviceIdentifier);
        }
        
        const catalogReviewMode = catalog?.reviewMode || 'buyer';
        // Enforce catalog reviewMode if it's explicitly set to something other than 'buyer' by admin
        // Otherwise, allow buyer to specify it, defaulting to 'buyer'
        const finalReviewMode = catalog?.reviewMode && catalog.reviewMode !== 'buyer' ? catalog.reviewMode : (data.reviewMode || 'buyer');

        const title = data.title || `${snapshot.serviceCode || serviceIdentifier} Campaign (${quantity} tasks)`;

        // Normalize requirements payload for simplified buyer form & legacy elements
        const reqs = data.requirements || {};
        const normalizedRequirements = {
            ...reqs,
            targetUrl: reqs.targetUrl || reqs.url || reqs.link || reqs.channelUrl || reqs.videoUrl || '',
            customText: reqs.customText || reqs.text || reqs.comment || reqs.instructions || data.description || '',
            watchTimeSeconds: reqs.watchTimeSeconds || catalog?.watchtimeSeconds || 0,
            videoTutorialUrl: catalog?.videoTutorialUrl || '',
            audioGuideUrl: catalog?.audioGuideUrl || '',
            adminInstructions: catalog?.adminInstructions || catalog?.description || '',
            serviceName: catalog?.name || title,
        };

        // Validate timing parameter bounds (1h-72h accept, 1h-168h complete)
        TimingPolicy.validateTiming(data.timeToAcceptHours, data.timeToCompleteHours);

        const timeToAccept = data.timeToAcceptHours || 24;
        const timeToComplete = data.timeToCompleteHours || 48;
        const campaignExpiryDate = data.campaignExpiryDate ? new Date(data.campaignExpiryDate) : undefined;
        const totalCost = Number(snapshot.totalAmount);

        // Deduct from buyer's wallet balance
        const deductionResult = await this.walletService.deductForOrder(
            user.id,
            totalCost,
            'temp_order',
            title,
        );

        const order = await this.orderRepo.create({
            buyerId: user.id,
            title,
            description: data.description,
            taskType: snapshot.serviceCode || serviceIdentifier,
            totalTasksRequired: quantity,
            rewardPerTask: snapshot.workerRewardSnapshot,
            buyerUnitPrice: snapshot.buyerUnitPrice,
            workerRewardSnapshot: snapshot.workerRewardSnapshot,
            platformMarginSnapshot: snapshot.marginAmount,
            serviceCode: snapshot.serviceCode || serviceIdentifier,
            pricingVersion: snapshot.pricingVersion,
            totalAmount: snapshot.totalAmount,
            status: 'ACTIVE',
            requirements: normalizedRequirements,
            reviewMode: finalReviewMode,
            timeToAcceptHours: timeToAccept,
            timeToCompleteHours: timeToComplete,
            campaignExpiryDate: campaignExpiryDate,
            timeToAcceptHoursSnapshot: timeToAccept,
            timeToCompleteHoursSnapshot: timeToComplete,
            campaignExpiryDateSnapshot: campaignExpiryDate,
        });

        // Trigger task generation queue directly via event
        try {
            this.eventEmitter.emit('order.activated', {
                orderId: order.id,
                buyerId: user.id,
                serviceCode: order.serviceCode,
                totalTasksRequired: order.totalTasksRequired,
                workerRewardSnapshot: order.workerRewardSnapshot,
                activatedAt: new Date(),
            });
        } catch (_) {}

        return {
            success: true,
            order: {
                id: order.id,
                title: order.title,
                taskType: order.taskType,
                totalTasksRequired: order.totalTasksRequired,
                buyerUnitPrice: order.buyerUnitPrice,
                totalAmount: order.totalAmount,
                status: order.status,
                pricingVersion: order.pricingVersion,
                createdAt: order.createdAt,
            },
            priceSnapshot: {
                buyerUnitPrice: snapshot.buyerUnitPrice,
                totalAmount: snapshot.totalAmount,
                pricingVersion: snapshot.pricingVersion,
            },
            wallet: {
                deductedAmount: deductionResult.deductedAmount,
                remainingBalance: deductionResult.remainingBalance,
            },
            message: `Campaign order created & paid ₹${totalCost.toFixed(2)} from wallet. Tasks are active!`,
        };
    }

    @Get('dashboard')
    @ApiOperation({ summary: 'Get buyer real-time dashboard data' })
    async getBuyerDashboard(@CurrentUser() user: User) {
        const orders = await this.orderRepo.findByBuyer(user.id);

        let totalSpend = 0;
        let activeOrdersCount = 0;
        let completedOrdersCount = 0;
        let totalTasksCount = 0;
        let completedTasksCount = 0;
        let inProgressTasksCount = 0;
        let pendingTasksCount = 0;
        let rejectedTasksCount = 0;

        const recentCampaigns = await Promise.all(
            orders.slice(0, 10).map(async (o) => {
                const tasks = await this.taskRepo.findByOrderId(o.id);
                const completed = tasks.filter(t => this.taskRepo.matchesStatus(t.status, 'completed')).length;
                const inProg = tasks.filter(t => this.taskRepo.matchesStatus(t.status, 'assigned') || this.taskRepo.matchesStatus(t.status, 'in_progress')).length;
                const underRev = tasks.filter(t => this.taskRepo.matchesStatus(t.status, 'submitted')).length;
                const rej = tasks.filter(t => this.taskRepo.matchesStatus(t.status, 'rejected')).length;
                const pend = Math.max(0, o.totalTasksRequired - completed - inProg - underRev - rej);

                const amt = Number(o.totalAmount || (Number(o.totalTasksRequired) * Number(o.buyerUnitPrice || o.rewardPerTask || 0)));
                totalSpend += amt;

                if (o.status === 'ACTIVE') activeOrdersCount++;
                if (o.status === 'COMPLETED') completedOrdersCount++;

                totalTasksCount += o.totalTasksRequired;
                completedTasksCount += completed;
                inProgressTasksCount += inProg;
                pendingTasksCount += pend;
                rejectedTasksCount += rej;

                return {
                    id: o.id,
                    name: o.title,
                    serviceType: o.requirements?.serviceName || o.serviceCode || o.taskType,
                    status: o.status,
                    totalTasks: o.totalTasksRequired,
                    completedTasks: completed,
                    pendingTasks: pend,
                    inProgressTasks: inProg,
                    amount: amt,
                    expiresIn: o.campaignExpiryDate ? `${Math.max(1, Math.round((new Date(o.campaignExpiryDate).getTime() - Date.now()) / (1000 * 3600 * 24)))} days` : '30 days',
                    createdAt: o.createdAt,
                };
            })
        );

        const overallCompletion = totalTasksCount > 0 ? (completedTasksCount / totalTasksCount) * 100 : 0;

        return {
            success: true,
            dashboard: {
                totalSpend,
                totalCampaigns: orders.length,
                activeCampaigns: activeOrdersCount,
                completedCampaigns: completedOrdersCount,
                pendingTasks: pendingTasksCount,
                inProgressTasks: inProgressTasksCount,
                completedTasks: completedTasksCount,
                overallCompletion,
                recentCampaigns,
            },
        };
    }

    @Get()
    @ApiOperation({ summary: 'List orders created by buyer (Hides worker rewards and internal margins)' })
    async getOrders(@CurrentUser() user: User) {
        const orders = await this.orderRepo.findByBuyer(user.id);
        const buyerSafeOrders = await Promise.all(orders.map(async (o) => {
            const tasks = await this.taskRepo.findByOrderId(o.id);
            const completed = tasks.filter(t => this.taskRepo.matchesStatus(t.status, 'completed')).length;
            const inProgress = tasks.filter(t => this.taskRepo.matchesStatus(t.status, 'assigned') || this.taskRepo.matchesStatus(t.status, 'in_progress')).length;
            const underReview = tasks.filter(t => this.taskRepo.matchesStatus(t.status, 'submitted')).length;
            const rejected = tasks.filter(t => this.taskRepo.matchesStatus(t.status, 'rejected')).length;
            const pending = Math.max(0, o.totalTasksRequired - completed - inProgress - underReview - rejected);

            const total = o.totalTasksRequired || tasks.length;
            const completionPercentage = total > 0 ? (completed / total) * 100 : 0;
            const approvalRate = (completed + rejected) > 0 ? (completed / (completed + rejected)) * 100 : 100;
            const rejectionRate = (completed + rejected) > 0 ? (rejected / (completed + rejected)) * 100 : 0;

            const computedStatus = (completed >= total && total > 0 && o.status !== 'CANCELLED') ? 'COMPLETED' : (o.status || 'ACTIVE');
            if (o.status !== computedStatus) {
                try {
                    await this.orderRepo.update(o.id, { status: computedStatus, tasksCompleted: completed });
                } catch (_) {}
            }

            return {
                id: o.id,
                title: o.title,
                name: o.title,
                serviceName: o.requirements?.serviceName || o.serviceCode || o.taskType,
                taskType: o.taskType,
                totalTasks: o.totalTasksRequired,
                totalTasksRequired: o.totalTasksRequired,
                completedTasks: completed || o.tasksCompleted || 0,
                tasksCompleted: completed || o.tasksCompleted || 0,
                inProgressTasks: inProgress,
                pendingTasks: pending,
                rejectedTasks: rejected,
                underReviewTasks: underReview,
                pendingReviews: underReview,
                completionPercentage,
                approvalRate,
                rejectionRate,
                averageReviewTimeMinutes: 15,
                buyerUnitPrice: o.buyerUnitPrice || o.rewardPerTask,
                totalAmount: o.totalAmount || Number(o.totalTasksRequired) * Number(o.rewardPerTask),
                spentAmount: (o.buyerUnitPrice || o.rewardPerTask) * (completed || o.tasksCompleted || 0),
                status: computedStatus,
                paymentStatus: 'PAID',
                requirements: o.requirements,
                createdAt: o.createdAt,
            };
        }));

        return {
            success: true,
            orders: buyerSafeOrders,
        };
    }

    @Get(':id')
    @ApiOperation({ summary: 'Get buyer-safe order details' })
    async getOrder(@Param('id') orderId: string, @CurrentUser() user: User) {
        const order = await this.orderRepo.findById(orderId);
        if (!order || order.buyerId !== user.id) {
            throw new NotFoundException('Order not found or access denied');
        }

        const tasks = await this.taskRepo.findByOrderId(order.id);
        const completed = tasks.filter(t => this.taskRepo.matchesStatus(t.status, 'completed')).length;
        const inProgress = tasks.filter(t => this.taskRepo.matchesStatus(t.status, 'assigned') || this.taskRepo.matchesStatus(t.status, 'in_progress')).length;
        const underReview = tasks.filter(t => this.taskRepo.matchesStatus(t.status, 'submitted')).length;
        const rejected = tasks.filter(t => this.taskRepo.matchesStatus(t.status, 'rejected')).length;
        const pending = Math.max(0, order.totalTasksRequired - completed - inProgress - underReview - rejected);

        const total = order.totalTasksRequired || tasks.length;
        const completionPercentage = total > 0 ? (completed / total) * 100 : 0;
        const approvalRate = (completed + rejected) > 0 ? (completed / (completed + rejected)) * 100 : 100;
        const rejectionRate = (completed + rejected) > 0 ? (rejected / (completed + rejected)) * 100 : 0;

        const computedStatus = (completed >= total && total > 0 && order.status !== 'CANCELLED') ? 'COMPLETED' : (order.status || 'ACTIVE');
        if (order.status !== computedStatus) {
            try {
                await this.orderRepo.update(order.id, { status: computedStatus, tasksCompleted: completed });
            } catch (_) {}
        }

        return {
            success: true,
            order: {
                id: order.id,
                title: order.title,
                name: order.title,
                description: order.description,
                serviceName: order.requirements?.serviceName || order.serviceCode || order.taskType,
                taskType: order.taskType,
                totalTasks: order.totalTasksRequired,
                totalTasksRequired: order.totalTasksRequired,
                completedTasks: completed || order.tasksCompleted || 0,
                tasksCompleted: completed || order.tasksCompleted || 0,
                inProgressTasks: inProgress,
                pendingTasks: pending,
                rejectedTasks: rejected,
                underReviewTasks: underReview,
                pendingReviews: underReview,
                completionPercentage,
                approvalRate,
                rejectionRate,
                averageReviewTimeMinutes: 15,
                buyerUnitPrice: order.buyerUnitPrice || order.rewardPerTask,
                totalAmount: order.totalAmount || Number(order.totalTasksRequired) * Number(order.rewardPerTask),
                spentAmount: (order.buyerUnitPrice || order.rewardPerTask) * (completed || order.tasksCompleted || 0),
                status: computedStatus,
                paymentStatus: 'PAID',
                requirements: order.requirements,
                createdAt: order.createdAt,
            },
        };
    }

    @Get(':id/progress')
    @ApiOperation({ summary: 'Get order progress and completion metrics' })
    async getOrderProgress(@Param('id') orderId: string, @CurrentUser() user: User) {
        const order = await this.orderRepo.findById(orderId);
        if (!order || order.buyerId !== user.id) {
            throw new NotFoundException('Order not found or access denied');
        }

        const progress = await this.progressEngine.getOrderProgress(orderId);
        return {
            success: true,
            progress,
        };
    }

    @Get(':id/tasks')
    @ApiOperation({ summary: 'Get all tasks associated with order' })
    async getOrderTasks(@Param('id') orderId: string, @CurrentUser() user: User) {
        const order = await this.orderRepo.findById(orderId);
        if (!order || order.buyerId !== user.id) {
            throw new NotFoundException('Order not found or access denied');
        }

        const tasks = await this.taskRepo.findByOrderId(orderId);
        return {
            success: true,
            tasks,
            count: tasks.length,
        };
    }

    @Get(':id/completed')
    @ApiOperation({ summary: 'Get completed tasks for order' })
    async getCompletedTasks(@Param('id') orderId: string, @CurrentUser() user: User) {
        const order = await this.orderRepo.findById(orderId);
        if (!order || order.buyerId !== user.id) {
            throw new NotFoundException('Order not found or access denied');
        }

        const tasks = await this.taskRepo.findByOrderId(orderId);
        const completed = this.taskRepo.filterByStatus(tasks, 'completed');

        return {
            success: true,
            tasks: completed,
            count: completed.length,
        };
    }

    @Get(':id/pending')
    @ApiOperation({ summary: 'Get submitted tasks pending review for order' })
    async getPendingTasks(@Param('id') orderId: string, @CurrentUser() user: User) {
        const order = await this.orderRepo.findById(orderId);
        if (!order || order.buyerId !== user.id) {
            throw new NotFoundException('Order not found or access denied');
        }

        const tasks = await this.taskRepo.findByOrderId(orderId);
        // Specifically filter submitted tasks that require verification/review
        const underReview = tasks.filter((task) =>
            this.taskRepo.matchesStatus(task.status, 'submitted') ||
            this.taskRepo.matchesStatus(task.status, 'under_review'),
        );

        const taskReviews = await Promise.all(underReview.map(async (t) => {
            let submission: any = null;
            try {
                submission = await this.submissionRepo.findByTaskId(t.id);
            } catch (_) {}

            let proofUrl = '';
            let proofText = '';

            if (submission) {
                if (Array.isArray(submission.proofs) && submission.proofs.length > 0) {
                    proofUrl = submission.proofs[0]?.url || submission.proofs[0]?.path || '';
                }
                if (!proofUrl && submission.data) {
                    proofUrl = submission.data.proofUrl || submission.data.screenshotUrl || '';
                }
                if (submission.data) {
                    proofText = submission.data.textProof || submission.data.proofText || submission.data.notes || '';
                }
            }

            return {
                id: submission ? submission.id : t.id,
                submissionId: submission ? submission.id : t.id,
                taskId: t.id,
                orderId: t.orderId,
                taskType: t.taskType,
                taskTitle: t.taskType || 'Task Execution',
                status: submission ? submission.status : t.status,
                workerId: t.assignedTo || submission?.workerId || 'Worker',
                workerName: 'Worker',
                proofUrl: proofUrl,
                proofScreenshotUrl: proofUrl,
                proofText: proofText,
                rewardAmount: t.rewardAmount,
                submittedAt: t.submittedAt || submission?.createdAt || t.updatedAt || t.createdAt,
                requirements: t.requirements,
                metadata: t.metadata,
                proofs: submission?.proofs || t.metadata?.proofs || t.requirements?.proofs || [],
                data: submission?.data || {},
            };
        }));

        return {
            success: true,
            tasks: taskReviews,
            count: taskReviews.length,
        };
    }

    @Get(':id/rejected')
    @ApiOperation({ summary: 'Get rejected tasks for order' })
    async getRejectedTasks(@Param('id') orderId: string, @CurrentUser() user: User) {
        const order = await this.orderRepo.findById(orderId);
        if (!order || order.buyerId !== user.id) {
            throw new NotFoundException('Order not found or access denied');
        }

        const tasks = await this.taskRepo.findByOrderId(orderId);
        const rejected = this.taskRepo.filterByStatus(tasks, 'rejected');

        return {
            success: true,
            tasks: rejected,
            count: rejected.length,
        };
    }

    @Get(':id/activity')
    @ApiOperation({ summary: 'Get order activity timeline' })
    async getOrderActivity(@Param('id') orderId: string, @CurrentUser() user: User) {
        const order = await this.orderRepo.findById(orderId);
        if (!order || order.buyerId !== user.id) {
            throw new NotFoundException('Order not found or access denied');
        }

        const tasks = await this.taskRepo.findByOrderId(orderId);
        const completed = tasks.filter(t => this.taskRepo.matchesStatus(t.status, 'completed'));
        const submitted = tasks.filter(t => this.taskRepo.matchesStatus(t.status, 'submitted'));
        const inProgress = tasks.filter(t => this.taskRepo.matchesStatus(t.status, 'assigned') || this.taskRepo.matchesStatus(t.status, 'in_progress'));

        const activities: Array<{ id: string; type: string; title: string; detail: string; timestamp: any }> = [
            {
                id: '1',
                type: 'ORDER_CREATED',
                title: 'Campaign Created',
                detail: `Campaign "${order.title}" launched and funded from buyer wallet.`,
                timestamp: order.createdAt,
            },
        ];

        if (tasks.length > 0) {
            activities.push({
                id: '2',
                type: 'TASKS_GENERATED',
                title: `${tasks.length} Tasks Enqueued`,
                detail: `Fulfillment queue generated for workers to discover in task feed.`,
                timestamp: order.createdAt,
            });
        }

        if (inProgress.length > 0) {
            activities.push({
                id: '3',
                type: 'WORKERS_ACTIVE',
                title: `${inProgress.length} Workers Active`,
                detail: `Workers have claimed and are currently performing tasks.`,
                timestamp: inProgress[0].startedAt || inProgress[0].assignedAt || new Date(),
            });
        }

        if (submitted.length > 0) {
            activities.push({
                id: '4',
                type: 'PROOFS_SUBMITTED',
                title: `${submitted.length} Proofs Under Review`,
                detail: `Workers submitted proof screenshots for quality verification.`,
                timestamp: submitted[0].submittedAt || new Date(),
            });
        }

        if (completed.length > 0) {
            activities.push({
                id: '5',
                type: 'TASKS_COMPLETED',
                title: `${completed.length} Tasks Completed`,
                detail: `Completed tasks verified and credited to workers.`,
                timestamp: completed[0].completedAt || new Date(),
            });
        }

        if (order.status === 'COMPLETED' || (tasks.length > 0 && completed.length === tasks.length)) {
            activities.push({
                id: '6',
                type: 'CAMPAIGN_COMPLETED',
                title: 'Campaign 100% Completed',
                detail: 'All tasks have been successfully delivered and finalized.',
                timestamp: order.updatedAt || new Date(),
            });
        }

        return {
            success: true,
            orderId: order.id,
            activity: activities.reverse(), // most recent first
        };
    }

    @Get(':id/analytics')
    @ApiOperation({ summary: 'Get detailed order analytics' })
    async getOrderAnalytics(@Param('id') orderId: string, @CurrentUser() user: User) {
        const order = await this.orderRepo.findById(orderId);
        if (!order || order.buyerId !== user.id) {
            throw new NotFoundException('Order not found or access denied');
        }

        const tasks = await this.taskRepo.findByOrderId(orderId);
        const completed = tasks.filter(t => this.taskRepo.matchesStatus(t.status, 'completed'));
        const inProgress = tasks.filter(t => this.taskRepo.matchesStatus(t.status, 'assigned') || this.taskRepo.matchesStatus(t.status, 'in_progress'));
        const underReview = tasks.filter(t => this.taskRepo.matchesStatus(t.status, 'submitted'));
        const rejected = tasks.filter(t => this.taskRepo.matchesStatus(t.status, 'rejected'));
        const pending = Math.max(0, order.totalTasksRequired - completed.length - inProgress.length - underReview.length - rejected.length);

        const total = order.totalTasksRequired || tasks.length;
        const completionRate = total > 0 ? (completed.length / total) * 100 : 0;
        const approvalRate = (completed.length + rejected.length) > 0 ? (completed.length / (completed.length + rejected.length)) * 100 : 100;
        const rejectionRate = (completed.length + rejected.length) > 0 ? (rejected.length / (completed.length + rejected.length)) * 100 : 0;

        // Daily weekday velocity count
        const velocity: Record<string, number> = { Mon: 0, Tue: 0, Wed: 0, Thu: 0, Fri: 0, Sat: 0, Sun: 0 };
        const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
        for (const t of completed) {
            const date = t.completedAt ? new Date(t.completedAt) : (t.updatedAt ? new Date(t.updatedAt) : new Date());
            const dayName = days[date.getDay()];
            if (velocity[dayName] !== undefined) {
                velocity[dayName]++;
            }
        }

        return {
            success: true,
            analytics: {
                orderId: order.id,
                totalRequired: order.totalTasksRequired,
                completedCount: completed.length,
                inProgressCount: inProgress.length,
                pendingCount: pending,
                rejectedCount: rejected.length,
                underReviewCount: underReview.length,
                completionRatePercentage: completionRate,
                approvalRatePercentage: approvalRate,
                rejectionRatePercentage: rejectionRate,
                unitPrice: order.buyerUnitPrice || order.rewardPerTask,
                totalAmount: order.totalAmount || Number(order.totalTasksRequired) * Number(order.rewardPerTask),
                totalAmountSpent: (order.buyerUnitPrice || order.rewardPerTask) * completed.length,
                averageReviewTimeMinutes: 15,
                weeklyVelocity: velocity,
            },
        };
    }

    @Post(':id/pause')
    @ApiOperation({ summary: 'Pause order campaign' })
    async pauseOrder(@Param('id') orderId: string, @CurrentUser() user: User) {
        const order = await this.orderRepo.findById(orderId);
        if (!order || order.buyerId !== user.id) {
            throw new NotFoundException('Order not found or access denied');
        }

        await this.orderRepo.update(orderId, { status: 'PAUSED' });
        return {
            success: true,
            message: 'Order paused successfully',
        };
    }

    @Post(':id/resume')
    @ApiOperation({ summary: 'Resume paused order campaign' })
    async resumeOrder(@Param('id') orderId: string, @CurrentUser() user: User) {
        const order = await this.orderRepo.findById(orderId);
        if (!order || order.buyerId !== user.id) {
            throw new NotFoundException('Order not found or access denied');
        }

        await this.orderRepo.update(orderId, { status: 'ACTIVE' });
        return {
            success: true,
            message: 'Order resumed successfully',
        };
    }

    @Post(':id/cancel')
    @ApiOperation({ summary: 'Cancel order' })
    async cancelOrder(@Param('id') orderId: string, @CurrentUser() user: User) {
        const order = await this.orderRepo.findById(orderId);
        if (!order || order.buyerId !== user.id) {
            throw new NotFoundException('Order not found or access denied');
        }

        await this.orderRepo.update(orderId, { status: 'CANCELLED' });
        return {
            success: true,
            message: 'Order cancelled',
        };
    }
}
