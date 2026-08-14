import { Injectable } from '@nestjs/common';
import { TaskRepository } from '../../shared/database/repositories/task.repository';
import { Reward } from '../types/reward';

/**
 * Reward snapshots manage karta hai
 * Task created time pe reward lock kar deta hai
 */
@Injectable()
export class RewardSnapshotService {
    constructor(private readonly taskRepo: TaskRepository) { }

    async create(taskId: string, reward: Reward): Promise<void> {
        const task = await this.taskRepo.findById(taskId);
        if (task) {
            const metadata = task.metadata || {};
            metadata.rewardSnapshot = {
                ...reward,
                taskId,
            };
            await this.taskRepo.update(taskId, { metadata });
        }
    }

    async get(taskId: string): Promise<Reward | null> {
        const task = await this.taskRepo.findById(taskId);
        if (task && task.metadata && task.metadata.rewardSnapshot) {
            return task.metadata.rewardSnapshot as Reward;
        }
        return null;
    }

    async exists(taskId: string): Promise<boolean> {
        const snapshot = await this.get(taskId);
        return snapshot !== null;
    }

    async delete(taskId: string): Promise<void> {
        const task = await this.taskRepo.findById(taskId);
        if (task && task.metadata && task.metadata.rewardSnapshot) {
            delete task.metadata.rewardSnapshot;
            await this.taskRepo.update(taskId, { metadata: task.metadata });
        }
    }
}
