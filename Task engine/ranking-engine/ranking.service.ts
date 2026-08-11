import { Injectable } from '@nestjs/common';
import { RankingCalculator } from './calculators/ranking-calculator';
import { RankedWorker } from './types/ranked-worker';

/**
 * Ranking Engine
 * Workers ko score aur priority ke basis pe rank karta hai
 */
@Injectable()
export class RankingEngineService {
    constructor(private readonly calculator: RankingCalculator) { }

    async rankWorkers(
        workerIds: string[],
        taskId: string,
    ): Promise<RankedWorker[]> {
        const ranked = await this.calculator.rank(workerIds, taskId);
        return ranked;
    }

    async getRankedList(
        workerIds: string[],
        limit?: number,
    ): Promise<RankedWorker[]> {
        const ranked = await this.calculator.rank(workerIds, null);

        if (limit) {
            return ranked.slice(0, limit);
        }

        return ranked;
    }
}
