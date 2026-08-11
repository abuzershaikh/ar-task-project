import { Injectable } from '@nestjs/common';
import { TaskRepository } from '../../shared/database/repositories/task.repository';
import { OrderRepository } from '../../shared/database/repositories/order.repository';
import { MatchingRequest, MatchingContext } from '../types';

/**
 * Matching ke liye context build karta hai
 */
@Injectable()
export class MatchingContextService {
    constructor(
        private readonly taskRepo: TaskRepository,
        private readonly orderRepo: OrderRepository,
    ) { }

    async buildContext(request: MatchingRequest): Promise<MatchingContext> {
        // Task fetch karo
        const task = await this.taskRepo.findById(request.taskId);
        if (!task) {
            throw new Error('Task not found');
        }

        // Order fetch karo
        const order = await this.orderRepo.findById(task.orderId);
        if (!order) {
            throw new Error('Order not found');
        }

        // Requirements extract karo
        const requirements = {
            ...order.requirements,
            ...task.requirements,
        };

        // Filters decide karo
        const filters = this.determineFilters(task, order, requirements);

        return {
            taskId: request.taskId,
            task,
            order,
            requirements,
            filters,
        };
    }

    private determineFilters(task: any, order: any, requirements: any): string[] {
        const filters: string[] = [];

        // Core filters (always apply)
        filters.push('active');
        filters.push('kyc');
        filters.push('capacity');

        // Conditional filters
        if (requirements.location) {
            filters.push('location');
        }

        if (requirements.category) {
            filters.push('category');
        }

        // Duplicate prevention
        filters.push('duplicate');

        return filters;
    }
}
