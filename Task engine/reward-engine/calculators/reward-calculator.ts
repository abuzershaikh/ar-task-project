import { Injectable } from '@nestjs/common';
import { TaskRepository } from '../../shared/database/repositories/task.repository';
import { OrderRepository } from '../../shared/database/repositories/order.repository';
import { Reward } from '../types/reward';

/**
 * Task ka reward amount calculate karta hai
 */
@Injectable()
export class RewardCalculator {
    constructor(
        private readonly taskRepo: TaskRepository,
        private readonly orderRepo: OrderRepository,
    ) { }

    async calculate(taskId: string): Promise<Reward> {
        const task = await this.taskRepo.findById(taskId);

        if (!task) {
            throw new Error('Task not found');
        }

        const order = await this.orderRepo.findById(task.orderId);

        if (!order) {
            throw new Error('Order not found');
        }

        // Base reward from order
        let baseReward = order.rewardPerTask;
        let bonus = 0;
        let totalReward = baseReward;

        // Apply bonuses based on task requirements
        if (task.requirements?.difficulty === 'hard') {
            bonus += baseReward * 0.20; // 20% bonus for hard tasks
        }

        if (task.requirements?.urgency === 'high') {
            bonus += baseReward * 0.15; // 15% bonus for urgent tasks
        }

        totalReward = baseReward + bonus;

        return {
            taskId,
            baseReward,
            bonus,
            totalReward,
            currency: 'INR',
            breakdown: {
                base: baseReward,
                difficultyBonus: task.requirements?.difficulty === 'hard' ? baseReward * 0.20 : 0,
                urgencyBonus: task.requirements?.urgency === 'high' ? baseReward * 0.15 : 0,
            },
        };
    }
}
