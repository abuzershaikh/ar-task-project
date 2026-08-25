import { Controller, Get, Param, NotFoundException } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { OrderRepository } from '../../../../shared/database/repositories/order.repository';
import { TaskRepository } from '../../../../shared/database/repositories/task.repository';
import { SubmissionRepository } from '../../../../shared/database/repositories/submission.repository';
import { UserRepository } from '../../../../shared/database/repositories/user.repository';
import { WorkerRepository } from '../../../../shared/database/repositories/worker.repository';
import { ProgressEngineService } from '../../../../progress-engine/progress.service';
import { Roles } from '../../../../shared/auth/decorators/roles.decorator';
import { UserRole } from '../../../../shared/database/entities/user.entity';

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
    ) { }

    @Get()
    @ApiOperation({ summary: 'List all orders across platform' })
    async listOrders() {
        const orders = await this.orderRepo.findActiveOrders();
        const buyers = await this.userRepo.findByRole(UserRole.BUYER).catch(() => []);
        const allUsers = await this.userRepo.findByRole(UserRole.WORKER).then((w) => [...buyers, ...w]).catch(() => buyers);

        const userMap = new Map<string, any>();
        for (const u of allUsers) {
            userMap.set(u.id, u);
            if (u.firebaseUid) userMap.set(u.firebaseUid, u);
        }

        const enriched = orders.map((o) => {
            const buyerUser = userMap.get(o.buyerId);
            const buyerName = (buyerUser as any)?.fullName || (buyerUser as any)?.name || (buyerUser?.email ? buyerUser.email.split('@')[0] : 'Direct Buyer');
            const buyerEmail = buyerUser?.email || '';

            return {
                ...o,
                buyerName,
                buyerEmail,
                buyerPhone: buyerUser?.phone || '',
            };
        });

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

        return {
            success: true,
            order: {
                ...order,
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
        for (const t of tasks) {
            const sub = await this.submissionRepo.findByTaskId(t.id);
            if (sub) {
                const workerUser = workerMap.get(sub.workerId || t.assignedTo);
                const workerName = (workerUser as any)?.fullName || (workerUser as any)?.name || (workerUser?.email ? workerUser.email.split('@')[0] : 'Worker');
                const workerEmail = workerUser?.email || '';

                submissions.push({
                    ...sub,
                    workerName,
                    workerEmail,
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
}

