import { Injectable, Logger } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { WorkerScoreRepository } from '../../shared/database/repositories/worker-score.repository';
import { RankedWorker } from '../types/ranked-worker';

/**
 * Workers ko rank karta hai score aur priority ke basis pe
 */
@Injectable()
export class RankingCalculator {
    private readonly logger = new Logger(RankingCalculator.name);

    constructor(
        private readonly scoreRepo: WorkerScoreRepository,
        private readonly eventEmitter: EventEmitter2
    ) { }

    async rank(workerIds: string[], taskId: string | null, precalculatedScores?: Map<string, number>): Promise<RankedWorker[]> {
        let scoreMap: Map<string, number>;
        if (precalculatedScores) {
            scoreMap = precalculatedScores;
        } else {
            const scores = await this.scoreRepo.findByWorkerIds(workerIds);
            scoreMap = new Map(scores.map(s => [s.workerId, s.totalScore]));
            
            // Detect missing scores and trigger recalculation
            const missingWorkerIds = workerIds.filter(id => !scoreMap.has(id));
            if (missingWorkerIds.length > 0) {
                this.logger.warn(`Missing scores for ${missingWorkerIds.length} workers. Triggering recalculation.`);
                missingWorkerIds.forEach(id => {
                    this.eventEmitter.emit('worker.score.recalculate', { workerId: id });
                });
            }
        }

        // Build ranked list
        const ranked: RankedWorker[] = workerIds.map(workerId => ({
            workerId,
            score: scoreMap.get(workerId) || 0,
            rank: 0,
            priority: this.calculatePriority(scoreMap.get(workerId) || 0),
        }));

        // Sort by score (descending) with deterministic workerId tie-breaker
        ranked.sort((a, b) => {
            if (b.score !== a.score) {
                return b.score - a.score;
            }
            return a.workerId.localeCompare(b.workerId);
        });

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
