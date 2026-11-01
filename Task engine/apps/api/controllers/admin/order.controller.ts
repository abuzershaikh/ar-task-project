import { Controller, Get, Post, Body, Param, NotFoundException } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { OrderRepository } from '../../../../shared/database/repositories/order.repository';
import { TaskRepository } from '../../../../shared/database/repositories/task.repository';
import { SubmissionRepository } from '../../../../shared/database/repositories/submission.repository';
import { UserRepository } from '../../../../shared/database/repositories/user.repository';
import { WorkerRepository } from '../../../../shared/database/repositories/worker.repository';
import { ProgressEngineService } from '../../../../progress-engine/progress.service';
import { AuditLogService } from '../../../../shared/services/audit-log.service';
import { Roles } from '../../../../shared/auth/decorators/roles.decorator';
import { CurrentUser } from '../../../../shared/auth/decorators/current-user.decorator';
import { User, UserRole } from '../../../../shared/database/entities/user.entity';

@ApiTags('Admin - Order Management')
@Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
@ApiBearerAuth('bearer')
@Controller('admin/orders')
export class AdminOrderController {
    constructor(
        private readonly orderRepo: OrderRepository,
        private readonly taskRepo: TaskRepository,
        private readonly submissionRepo: SubmissionRepository,
        private readonly userRepo: UserRepository,
        private readonly workerRepo: WorkerRepository,
        private readonly progressEngine: ProgressEngineService,
        private readonly auditLogService: AuditLogService,
        private readonly eventEmitter: EventEmitter2,
    ) { }

    @Get()
    @ApiOperation({ summary: 'List all orders across platform' })
    async listOrders() {
        const orders = await this.orderRepo.findAll();
        const buyers = await this.userRepo.findByRole(UserRole.BUYER).catch(() => []);
        const allUsers = await this.userRepo.findByRole(UserRole.WORKER).then((w) => [...buyers, ...w]).catch(() => buyers);

        const userMap = new Map<string, any>();
        for (const u of allUsers) {
            userMap.set(u.id, u);
            if (u.firebaseUid) userMap.set(u.firebaseUid, u);
        }

        const enriched = await Promise.all(orders.map(async (o) => {
            const buyerUser = userMap.get(o.buyerId);
            const buyerName = (buyerUser as any)?.fullName || (buyerUser as any)?.name || (buyerUser?.email ? buyerUser.email.split('@')[0] : 'Direct Buyer');
            const buyerEmail = buyerUser?.email || '';

            // Automatically check and sync COMPLETED status
            let currentStatus = (o.status || 'ACTIVE').toUpperCase();
            const totalRequired = Number(o.totalTasksRequired || 0);
            const completedCount = Number(o.tasksCompleted || 0);

            if (totalRequired > 0 && completedCount >= totalRequired && currentStatus !== 'CANCELLED' && currentStatus !== 'PAUSED') {
                if (currentStatus !== 'COMPLETED') {
                    currentStatus = 'COMPLETED';
                    try {
                        await this.orderRepo.update(o.id, { status: 'COMPLETED' });
                    } catch (_) {}
                }
            }

            return {
                ...o,
                status: currentStatus,
                buyerName,
                buyerEmail,
                buyerPhone: buyerUser?.phone || '',
            };
        }));

        return {
            success: true,
            orders: enriched,
            total: enriched.length,
        };
    }

    @Get(':id')
    @ApiOperation({ summary: 'Get order detail with breakdown metrics' })
    async getOrderDetail(@Param('id') orderId: string) {
        const order = await this.orderRepo.findById(orderId);
        if (!order) {
            throw new NotFoundException('Order not found');
        }

        let buyerUser = await this.userRepo.findById(order.buyerId).catch(() => null);
        if (!buyerUser) {
            const buyers = await this.userRepo.findByRole(UserRole.BUYER).catch(() => []);
            buyerUser = buyers.find((b) => b.id === order.buyerId || b.firebaseUid === order.buyerId) || null;
        }

        const buyerName = (buyerUser as any)?.fullName || (buyerUser as any)?.name || (buyerUser?.email ? buyerUser.email.split('@')[0] : 'Direct Buyer');
        const buyerEmail = buyerUser?.email || '';

        const tasks = await this.taskRepo.findByOrderId(orderId);
        const assigned = this.taskRepo.filterByStatus(tasks, 'assigned').length;
        const accepted = this.taskRepo.filterByStatus(tasks, 'in_progress').length;
        const submitted = this.taskRepo.filterByStatus(tasks, 'submitted').length;
        const approved = this.taskRepo.filterByStatus(tasks, 'completed').length;
        const rejected = this.taskRepo.filterByStatus(tasks, 'rejected').length;
        const pending = this.taskRepo.filterByStatus(tasks, 'pending').length;

        // Auto-check completed status
        let currentStatus = (order.status || 'ACTIVE').toUpperCase();
        const totalRequired = Number(order.totalTasksRequired || 0);
        const completedCount = Math.max(Number(order.tasksCompleted || 0), approved);
        if (totalRequired > 0 && completedCount >= totalRequired && currentStatus !== 'CANCELLED' && currentStatus !== 'PAUSED') {
            if (currentStatus !== 'COMPLETED') {
                currentStatus = 'COMPLETED';
                try {
                    await this.orderRepo.update(order.id, { status: 'COMPLETED', tasksCompleted: completedCount });
                } catch (_) {}
            }
        }

        return {
            success: true,
            order: {
                ...order,
                status: currentStatus,
                tasksCompleted: completedCount,
                buyerName,
                buyerEmail,
                buyerPhone: buyerUser?.phone || '',
            },
            metrics: {
                totalRequired: order.totalTasksRequired,
                assigned,
                accepted,
                submitted,
                approved,
                rejected,
                pending,
            },
        };
    }

    @Get(':id/progress')
    @ApiOperation({ summary: 'Get progress metrics for order' })
    async getOrderProgress(@Param('id') orderId: string) {
        const progress = await this.progressEngine.getOrderProgress(orderId);
        return { success: true, progress };
    }

    @Get(':id/tasks')
    @ApiOperation({ summary: 'List tasks associated with order' })
    async getOrderTasks(@Param('id') orderId: string) {
        const tasks = await this.taskRepo.findByOrderId(orderId);
        const workers = await this.userRepo.findByRole(UserRole.WORKER).catch(() => []);
        const workerEntities = await this.workerRepo.findActiveWorkers().catch(() => []);

        const workerMap = new Map<string, any>();
        for (const w of workers) {
            workerMap.set(w.id, w);
            if (w.firebaseUid) workerMap.set(w.firebaseUid, w);
        }
        for (const we of workerEntities) {
            if (we.userId) {
                const u = workerMap.get(we.userId);
                if (u) workerMap.set(we.id, u);
            }
        }

        const enriched = tasks.map((t) => {
            const workerUser = workerMap.get(t.assignedTo || (t as any).workerId);
            const workerName = (workerUser as any)?.fullName || (workerUser as any)?.name || (workerUser?.email ? workerUser.email.split('@')[0] : 'Assigned Worker');
            const workerEmail = workerUser?.email || '';

            return {
                ...t,
                workerName,
                workerEmail,
            };
        });

        return { success: true, tasks: enriched, total: enriched.length };
    }

    @Get(':id/submissions')
    @ApiOperation({ summary: 'List submissions for order' })
    async getOrderSubmissions(@Param('id') orderId: string) {
        const tasks = await this.taskRepo.findByOrderId(orderId);
        const workers = await this.userRepo.findByRole(UserRole.WORKER).catch(() => []);
        const workerEntities = await this.workerRepo.findActiveWorkers().catch(() => []);

        const workerMap = new Map<string, any>();
        for (const w of workers) {
            workerMap.set(w.id, w);
            if (w.firebaseUid) workerMap.set(w.firebaseUid, w);
        }
        for (const we of workerEntities) {
            if (we.userId) {
                const u = workerMap.get(we.userId);
                if (u) workerMap.set(we.id, u);
            }
        }

        let submissions: any[] = [];
        const appUrl = process.env.APP_URL || 'http://65.20.77.112:3000';
        for (const t of tasks) {
            const sub = await this.submissionRepo.findByTaskId(t.id);
            if (sub) {
                const workerUser = workerMap.get(sub.workerId || t.assignedTo);
                const workerName = (workerUser as any)?.fullName || (workerUser as any)?.name || (workerUser?.email ? workerUser.email.split('@')[0] : 'Worker');
                const workerEmail = workerUser?.email || '';

                let proofUrl = '';
                if (Array.isArray(sub.proofs) && sub.proofs.length > 0) {
                    proofUrl = sub.proofs[0]?.url || sub.proofs[0]?.path || '';
                }
                if (!proofUrl && sub.data) {
                    proofUrl = sub.data.proofUrl || sub.data.screenshotUrl || '';
                }
                if (proofUrl && !proofUrl.startsWith('http')) {
                    if (proofUrl.startsWith('/')) {
                        proofUrl = `${appUrl}${proofUrl}`;
                    } else if (proofUrl.includes('/')) {
                        proofUrl = `${appUrl}/api/v1/files/raw/${encodeURIComponent(proofUrl)}`;
                    } else {
                        proofUrl = `${appUrl}/api/v1/files/raw/${proofUrl}`;
                    }
                }

                let proofText = '';
                if (sub.data) {
                    proofText = sub.data.textProof || sub.data.proofText || sub.data.notes || '';
                }

                submissions.push({
                    ...sub,
                    submissionId: sub.id,
                    taskTitle: t.taskType || 'Task Execution',
                    orderId: t.orderId || orderId,
                    workerName,
                    workerEmail,
                    proofUrl,
                    proofScreenshotUrl: proofUrl,
                    proofText,
                });
            }
        }
        return { success: true, submissions, total: submissions.length };
    }

    @Get(':id/activity')
    @ApiOperation({ summary: 'Get order activity timeline' })
    async getOrderActivity(@Param('id') orderId: string) {
        const order = await this.orderRepo.findById(orderId);
        if (!order) throw new NotFoundException('Order not found');

        return {
            success: true,
            orderId: order.id,
            timeline: [
                { status: 'CREATED', timestamp: order.createdAt },
            ],
        };
    }

    @Post(':id/pause')
    @ApiOperation({ summary: 'Pause campaign allocation from Admin App' })
    async pauseOrder(
        @Param('id') orderId: string,
        @Body() body: any,
        @CurrentUser() currentUser?: User,
    ) {
        const order = await this.orderRepo.findById(orderId);
        if (!order) {
            throw new NotFoundException('Campaign not found');
        }

        const previousStatus = order.status;
        order.status = 'PAUSED';
        await this.orderRepo.save(order);

        // Record central audit log
        try {
            await this.auditLogService.logAction({
                userId: currentUser?.id || 'ADMIN',
                action: 'CAMPAIGN_PAUSED',
                targetType: 'ORDER',
                targetId: orderId,
                previousValue: { status: previousStatus },
                newValue: { status: 'PAUSED' },
                metadata: { reason: body?.reason || 'Campaign paused by administrator' },
            });
        } catch (_) {}

        this.eventEmitter.emit('order.paused', { orderId });

        return {
            success: true,
            message: 'Campaign has been paused successfully',
            orderId,
            status: 'PAUSED',
        };
    }

    @Post(':id/resume')
    @ApiOperation({ summary: 'Resume paused campaign from Admin App' })
    async resumeOrder(
        @Param('id') orderId: string,
        @CurrentUser() currentUser?: User,
    ) {
        const order = await this.orderRepo.findById(orderId);
        if (!order) {
            throw new NotFoundException('Campaign not found');
        }

        const previousStatus = order.status;
        order.status = 'ACTIVE';
        await this.orderRepo.save(order);

        // Record central audit log
        try {
            await this.auditLogService.logAction({
                userId: currentUser?.id || 'ADMIN',
                action: 'CAMPAIGN_RESUMED',
                targetType: 'ORDER',
                targetId: orderId,
                previousValue: { status: previousStatus },
                newValue: { status: 'ACTIVE' },
                metadata: { resumedAt: new Date().toISOString() },
            });
        } catch (_) {}

        this.eventEmitter.emit('order.resumed', { orderId });

        return {
            success: true,
            message: 'Campaign has been resumed successfully',
            orderId,
            status: 'ACTIVE',
        };
    }

    @Post(':id/cancel')
    @ApiOperation({ summary: 'Cancel campaign and refund unused budget from Admin App' })
    async cancelOrder(
        @Param('id') orderId: string,
        @Body() body: { reason?: string },
        @CurrentUser() currentUser?: User,
    ) {
        const order = await this.orderRepo.findById(orderId);
        if (!order) {
            throw new NotFoundException('Campaign not found');
        }

        const reason = body?.reason || 'Cancelled by Administrator';
        const previousStatus = order.status;
        order.status = 'CANCELLED';
        await this.orderRepo.save(order);

        // Cancel any pending / unassigned tasks for this order
        try {
            const tasks = await this.taskRepo.findByOrderId(orderId);
            for (const t of tasks) {
                const s = (t.status || '').toLowerCase();
                if (s === 'active' || s === 'pending' || s === 'created' || s === 'available') {
                    await this.taskRepo.update(t.id, { status: 'cancelled' as any });
                }
            }
        } catch (_) {}

        // Record central audit log
        try {
            await this.auditLogService.logAction({
                userId: currentUser?.id || 'ADMIN',
                action: 'CAMPAIGN_CANCELLED',
                targetType: 'ORDER',
                targetId: orderId,
                previousValue: { status: previousStatus },
                newValue: { status: 'CANCELLED' },
                metadata: { reason },
            });
        } catch (_) {}

        this.eventEmitter.emit('order.cancelled', { orderId, reason });

        return {
            success: true,
            message: 'Campaign has been cancelled successfully',
            orderId,
            status: 'CANCELLED',
            reason,
        };
    }
}

