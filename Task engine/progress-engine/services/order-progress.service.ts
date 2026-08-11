import { Injectable } from '@nestjs/common';
import { TaskRepository } from '../../shared/database/repositories/task.repository';
import { OrderRepository } from '../../shared/database/repositories/order.repository';

/**
 * Order ka progress track karta hai
 */
@Injectable()
export class OrderProgressService {
    constructor(
        private readonly taskRepo: TaskRepository,
        private readonly orderRepo: OrderRepository,
    ) { }

    async getProgress(orderId: string) {
        const order = await this.orderRepo.findById(orderId);
        if (!order) {
            throw new Error('Order not found');
        }

        const tasks = await this.taskRepo.findByOrderId(orderId);

        const total = order.totalTasksRequired;
        const created = tasks.length;
        const assigned = tasks.filter(t => t.status === 'assigned' || t.assignedTo).length;
        const inProgress = tasks.filter(t => ['accepted', 'in_progress'].includes(t.status)).length;
        const submitted = tasks.filter(t => t.status === 'submitted').length;
        const approved = tasks.filter(t => t.status === 'completed').length;
        const rejected = tasks.filter(t => t.status === 'rejected').length;
        const pending = assigned - (approved + rejected + submitted + inProgress);

        const completionRate = total > 0 ? (approved / total) * 100 : 0;

        return {
            orderId,
            total,
            created,
            assigned,
            inProgress,
            submitted,
            approved,
            rejected,
            pending,
            completionRate: Math.round(completionRate * 100) / 100,
            status: order.status,
        };
    }
}
