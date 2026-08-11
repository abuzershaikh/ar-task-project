import { Controller, Get, Param, NotFoundException } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { OrderRepository } from '../../../../shared/database/repositories/order.repository';
import { TaskRepository } from '../../../../shared/database/repositories/task.repository';
import { SubmissionRepository } from '../../../../shared/database/repositories/submission.repository';
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
        private readonly progressEngine: ProgressEngineService,
    ) { }

    @Get()
    @ApiOperation({ summary: 'List all orders across platform' })
    async listOrders() {
        const orders = await this.orderRepo.findActiveOrders();
        return {
            success: true,
            orders,
            total: orders.length,
        };
    }

    @Get(':id')
    @ApiOperation({ summary: 'Get order detail with breakdown metrics' })
    async getOrderDetail(@Param('id') orderId: string) {
        const order = await this.orderRepo.findById(orderId);
        if (!order) {
            throw new NotFoundException('Order not found');
        }

        const tasks = await this.taskRepo.findByOrderId(orderId);
        const assigned = this.taskRepo.filterByStatus(tasks, 'assigned').length;
        const accepted = this.taskRepo.filterByStatus(tasks, 'in_progress').length;
        const submitted = this.taskRepo.filterByStatus(tasks, 'submitted').length;
        const approved = this.taskRepo.filterByStatus(tasks, 'completed').length;
        const rejected = this.taskRepo.filterByStatus(tasks, 'rejected').length;
        const pending = this.taskRepo.filterByStatus(tasks, 'pending').length;

        return {
            success: true,
            order,
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
        return { success: true, tasks, total: tasks.length };
    }

    @Get(':id/submissions')
    @ApiOperation({ summary: 'List submissions for order' })
    async getOrderSubmissions(@Param('id') orderId: string) {
        const tasks = await this.taskRepo.findByOrderId(orderId);
        let submissions: any[] = [];
        for (const t of tasks) {
            const sub = await this.submissionRepo.findByTaskId(t.id);
            if (sub) submissions.push(sub);
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
