import { Injectable } from '@nestjs/common';
import { Reward } from '../types/reward';

/**
 * Reward snapshots manage karta hai
 * Task created time pe reward lock kar deta hai
 */
@Injectable()
export class RewardSnapshotService {
    private snapshots = new Map<string, Reward>();

    async create(taskId: string, reward: Reward): Promise<void> {
        this.snapshots.set(taskId, {
            ...reward,
            taskId,
        });
    }

    async get(taskId: string): Promise<Reward | null> {
        return this.snapshots.get(taskId) || null;
    }

    async exists(taskId: string): Promise<boolean> {
        return this.snapshots.has(taskId);
    }

    async delete(taskId: string): Promise<void> {
        this.snapshots.delete(taskId);
    }
}
