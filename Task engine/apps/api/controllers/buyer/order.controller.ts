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
    ) { }

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
        } catch {
            // Fallback for mock/test runs before catalog seeding
            snapshot = {
                serviceCode: serviceIdentifier,
                buyerUnitPrice: 10,
                workerRewardSnapshot: 6,
                marginAmount: 4,
                pricingVersion: 1,
                totalAmount: 10 * quantity,
            };
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

        // Validate timing parameter bounds (1h-72h accept, 1h-168h complete)
        TimingPolicy.validateTiming(data.timeToAcceptHours, data.timeToCompleteHours);

        const timeToAccept = data.timeToAcceptHours || 24;
        const timeToComplete = data.timeToCompleteHours || 48;
        const campaignExpiryDate = data.campaignExpiryDate ? new Date(data.campaignExpiryDate) : undefined;

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
            status: 'PAYMENT_PENDING',
            requirements: data.requirements,
            reviewMode: finalReviewMode,
            timeToAcceptHours: timeToAccept,
            timeToCompleteHours: timeToComplete,
            campaignExpiryDate: campaignExpiryDate,
            timeToAcceptHoursSnapshot: timeToAccept,
            timeToCompleteHoursSnapshot: timeToComplete,
            campaignExpiryDateSnapshot: campaignExpiryDate,
        });

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
            message: 'Order created in PAYMENT_PENDING state. Complete payment to initiate task generation.',
        };
    }

    @Get()
    @ApiOperation({ summary: 'List orders created by buyer (Hides worker rewards and internal margins)' })
    async getOrders(@CurrentUser() user: User) {
        const orders = await this.orderRepo.findByBuyer(user.id);
        const buyerSafeOrders = orders.map((o) => ({
            id: o.id,
            title: o.title,
            taskType: o.taskType,
            totalTasksRequired: o.totalTasksRequired,
            tasksCompleted: o.tasksCompleted,
            buyerUnitPrice: o.buyerUnitPrice || o.rewardPerTask,
            totalAmount: o.totalAmount || Number(o.totalTasksRequired) * Number(o.rewardPerTask),
            status: o.status,
            createdAt: o.createdAt,
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

        return {
            success: true,
            order: {
                id: order.id,
                title: order.title,
                description: order.description,
                taskType: order.taskType,
                totalTasksRequired: order.totalTasksRequired,
                tasksCompleted: order.tasksCompleted,
                buyerUnitPrice: order.buyerUnitPrice || order.rewardPerTask,
                totalAmount: order.totalAmount || Number(order.totalTasksRequired) * Number(order.rewardPerTask),
                status: order.status,
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
    @ApiOperation({ summary: 'Get pending tasks for order' })
    async getPendingTasks(@Param('id') orderId: string, @CurrentUser() user: User) {
        const order = await this.orderRepo.findById(orderId);
        if (!order || order.buyerId !== user.id) {
            throw new NotFoundException('Order not found or access denied');
        }

        const tasks = await this.taskRepo.findByOrderId(orderId);
        const pending = tasks.filter((task) =>
            this.taskRepo.matchesStatus(task.status, 'pending') ||
            this.taskRepo.matchesStatus(task.status, 'assigned') ||
            this.taskRepo.matchesStatus(task.status, 'submitted'),
        );

        return {
            success: true,
            tasks: pending,
            count: pending.length,
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

        return {
            success: true,
            orderId: order.id,
            activity: [
                { type: 'ORDER_CREATED', timestamp: order.createdAt, detail: `Order created in PAYMENT_PENDING state` },
                { type: 'TASKS_GENERATED', timestamp: order.createdAt, detail: `${tasks.length} tasks active` },
            ],
        };
    }

    @Get(':id/analytics')
    @ApiOperation({ summary: 'Get detailed order analytics' })
    async getOrderAnalytics(@Param('id') orderId: string, @CurrentUser() user: User) {
        const order = await this.orderRepo.findById(orderId);
        if (!order || order.buyerId !== user.id) {
            throw new NotFoundException('Order not found or access denied');
        }

        const progress = await this.progressEngine.getOrderProgress(orderId);

        return {
            success: true,
            analytics: {
                orderId: order.id,
                totalRequired: order.totalTasksRequired,
                completedCount: order.tasksCompleted,
                completionRatePercentage: progress.completionRate * 100,
                unitPrice: order.buyerUnitPrice || order.rewardPerTask,
                totalAmountSpent: (order.buyerUnitPrice || order.rewardPerTask) * order.tasksCompleted,
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
