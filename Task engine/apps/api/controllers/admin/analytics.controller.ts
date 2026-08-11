import { Controller, Get, Query } from '@nestjs/common';
import { TaskRepository } from '../../../../shared/database/repositories/task.repository';
import { WorkerRepository } from '../../../../shared/database/repositories/worker.repository';
import { OrderRepository } from '../../../../shared/database/repositories/order.repository';
import { Roles } from '../../../../shared/auth/decorators/roles.decorator';
import { UserRole } from '../../../../shared/database/entities/user.entity';

/**
 * Admin Analytics APIs
 */
@Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
@Controller('admin/analytics')
export class AdminAnalyticsController {
    constructor(
        private readonly taskRepo: TaskRepository,
        private readonly workerRepo: WorkerRepository,
        private readonly orderRepo: OrderRepository,
    ) { }

    @Get('overview')
    async getOverview() {
        const activeOrders = await this.orderRepo.findActiveOrders();
        const activeWorkers = await this.workerRepo.findActiveWorkers();

        const totalTasks = await this.taskRepo.countByStatus('completed');
        const pendingTasks = await this.taskRepo.countByStatus('pending');

        return {
            success: true,
            overview: {
                totalOrders: activeOrders.length,
                totalWorkers: activeWorkers.length,
                totalTasks,
                pendingTasks,
                completedTasks: totalTasks,
            },
        };
    }

    @Get('tasks')
    async getTaskAnalytics(@Query('period') period: string) {
        // TODO: Implement task analytics by period
        return {
            success: true,
            analytics: {
                created: 0,
                assigned: 0,
                completed: 0,
                rejected: 0,
            },
        };
    }

    @Get('workers')
    async getWorkerAnalytics() {
        const workers = await this.workerRepo.findActiveWorkers();

        return {
            success: true,
            analytics: {
                total: workers.length,
                active: workers.filter((worker) => worker.status?.toLowerCase() === 'active').length,
                kycPending: workers.filter((worker) => worker.kycStatus?.toLowerCase() === 'pending').length,
                kycApproved: workers.filter((worker) => worker.kycStatus?.toLowerCase() === 'approved').length,
            },
        };
    }

    @Get('revenue')
    async getRevenueAnalytics() {
        // TODO: Calculate revenue analytics
        return {
            success: true,
            revenue: {
                total: 0,
                thisMonth: 0,
                lastMonth: 0,
            },
        };
    }
}
