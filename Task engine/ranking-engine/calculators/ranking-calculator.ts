import { Injectable, Logger } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { WorkerScoreRepository } from '../../shared/database/repositories/worker-score.repository';
import { WorkerRepository } from '../../shared/database/repositories/worker.repository';
import { RankedWorker } from '../types/ranked-worker';

/**
 * Workers ko rank karta hai score aur priority ke basis pe
 * 
 * 5-TIER PRIORITY SYSTEM:
 * Score 90-100  → ⭐⭐⭐⭐⭐ critical  — Sabse pehle / high-value tasks
 * Score 75-89   → ⭐⭐⭐⭐   high      — High priority
 * Score 60-74   → ⭐⭐⭐     normal    — Normal tasks
 * Score 40-59   → ⭐⭐       low       — Low priority
 * Score 0-39    → ⭐         very_low  — Won't get tasks (min threshold 40)
 * 
 * ACTIVITY DEPRIORITIZATION:
 * 24-48h inactive → rank penalty (pushed lower)
 */
@Injectable()
export class RankingCalculator {
    private readonly logger = new Logger(RankingCalculator.name);

    constructor(
        private readonly scoreRepo: WorkerScoreRepository,
        private readonly workerRepo: WorkerRepository,
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
                    this.eventEmitter.emit('worker.score.recalculate', id);
                });
            }
        }

        // Fetch workers for activity status check
        const workers = await this.workerRepo.findByIds(workerIds);
        const workerMap = new Map(workers.map(w => [w.id, w]));

        // Build ranked list with activity-adjusted scores
        const ranked: RankedWorker[] = workerIds.map(workerId => {
            const baseScore = scoreMap.get(workerId) || 0;
            const worker = workerMap.get(workerId);
            const activityStatus = worker ? this.workerRepo.getActivityStatus(worker) : 'INACTIVE';

            // Activity deprioritization: WARNING status gets rank penalty
            let effectiveScore = baseScore;
            if (activityStatus === 'WARNING') {
                // 24-48h inactive: reduce effective score by 15% for ranking purposes
                // Note: actual score is NOT changed, only ranking position
                effectiveScore = baseScore * 0.85;
            }

            return {
                workerId,
                score: baseScore,  // Keep original score (not the adjusted one)
                rank: 0,
                priority: this.calculatePriority(baseScore),
                activityStatus,
                metadata: {
                    effectiveScore: Math.round(effectiveScore * 100) / 100,
                    activityPenalty: activityStatus === 'WARNING',
                },
            };
        });

        // Sort by effective score (descending) with deterministic workerId tie-breaker
        ranked.sort((a, b) => {
            const aEffective = a.metadata?.effectiveScore ?? a.score;
            const bEffective = b.metadata?.effectiveScore ?? b.score;
            if (bEffective !== aEffective) {
                return bEffective - aEffective;
            }
            return a.workerId.localeCompare(b.workerId);
        });

        // Assign ranks
        ranked.forEach((worker, index) => {
            worker.rank = index + 1;
        });

        return ranked;
    }

    /**
     * 5-tier priority system as per spec
     */
    private calculatePriority(score: number): string {
        if (score >= 90) return 'critical';   // ⭐⭐⭐⭐⭐ Sabse pehle / high-value tasks
        if (score >= 75) return 'high';       // ⭐⭐⭐⭐   High priority
        if (score >= 60) return 'normal';     // ⭐⭐⭐     Normal tasks
        if (score >= 40) return 'low';        // ⭐⭐       Low priority
        return 'very_low';                    // ⭐         Very low / no automatic tasks
    }
}
