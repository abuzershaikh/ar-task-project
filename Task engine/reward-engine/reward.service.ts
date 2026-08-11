import { Injectable } from '@nestjs/common';
import { RewardCalculator } from './calculators/reward-calculator';
import { RewardSnapshotService } from './services/reward-snapshot.service';
import { Reward } from './types/reward';

/**
 * Reward Engine
 * Task ka reward amount calculate karta hai
 */
@Injectable()
export class RewardEngineService {
    constructor(
        private readonly calculator: RewardCalculator,
        private readonly snapshotService: RewardSnapshotService,
    ) { }

    async calculateReward(taskId: string): Promise<Reward> {
        const reward = await this.calculator.calculate(taskId);
        return reward;
    }

    async createSnapshot(taskId: string): Promise<void> {
        const reward = await this.calculateReward(taskId);
        await this.snapshotService.create(taskId, reward);
    }

    async getSnapshotReward(taskId: string): Promise<Reward> {
        return this.snapshotService.get(taskId);
    }
}
