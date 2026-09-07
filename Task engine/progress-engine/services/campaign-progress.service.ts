import { Injectable } from '@nestjs/common';
import { TaskRepository } from '../../shared/database/repositories/task.repository';

/**
 * Campaign ka progress track karta hai
 */
@Injectable()
export class CampaignProgressService {
    constructor(private readonly taskRepo: TaskRepository) { }

    async getProgress(campaignId: string) {
        const tasks = await this.taskRepo.findByOrderId(campaignId);
        const completedTasks = tasks.filter(t => this.taskRepo.matchesStatus(t.status, 'completed')).length;
        const uniqueWorkers = new Set(tasks.map(t => t.assignedTo).filter(Boolean));
        const totalReward = tasks.reduce((sum, t) => sum + (Number(t.rewardAmount) || 0), 0);

        return {
            campaignId,
            totalOrders: 1,
            totalTasks: tasks.length,
            completedTasks,
            activeWorkers: uniqueWorkers.size,
            revenue: totalReward,
        };
    }
}
