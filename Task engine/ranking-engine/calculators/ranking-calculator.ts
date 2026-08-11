import { Injectable } from '@nestjs/common';
import { WorkerScoreRepository } from '../../shared/database/repositories/worker-score.repository';
import { RankedWorker } from '../types/ranked-worker';

/**
 * Workers ko rank karta hai score aur priority ke basis pe
 */
@Injectable()
export class RankingCalculator {
    constructor(private readonly scoreRepo: WorkerScoreRepository) { }

    async rank(workerIds: string[], taskId: string | null): Promise<RankedWorker[]> {
        // Get scores for all workers
        const scores = await this.scoreRepo.findByWorkerIds(workerIds);

        const scoreMap = new Map(scores.map(s => [s.workerId, s.totalScore]));

        // Build ranked list
        const ranked: RankedWorker[] = workerIds.map(workerId => ({
            workerId,
            score: scoreMap.get(workerId) || 0,
            rank: 0,
            priority: this.calculatePriority(scoreMap.get(workerId) || 0),
        }));

        // Sort by score (descending)
        ranked.sort((a, b) => b.score - a.score);

        // Assign ranks
        ranked.forEach((worker, index) => {
            worker.rank = index + 1;
        });

        return ranked;
    }

    private calculatePriority(score: number): string {
        if (score >= 90) return 'high';
        if (score >= 70) return 'medium';
        return 'low';
    }
}
