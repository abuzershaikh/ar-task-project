import { Injectable, Logger } from '@nestjs/common';
import { ScoreCalculator } from './calculators/score-calculator';
import { WorkerScore } from './types/worker-score';
import { WorkerScoreRepository } from '../shared/database/repositories/worker-score.repository';
import { WorkerRepository } from '../shared/database/repositories/worker.repository';

/**
 * Scoring Engine
 * Worker ka performance score calculate karta hai aur DB (worker_scores) me persist karta hai
 */
@Injectable()
export class ScoringEngineService {
    private readonly logger = new Logger(ScoringEngineService.name);

    constructor(
        private readonly calculator: ScoreCalculator,
        private readonly scoreRepo: WorkerScoreRepository,
        private readonly workerRepo: WorkerRepository,
    ) { }

    async calculateWorkerScore(idOrUserId: string): Promise<WorkerScore> {
        if (!idOrUserId) {
            throw new Error('Worker ID is required to calculate score');
        }

        const worker = await this.workerRepo.findWorker(idOrUserId);
        if (!worker) {
            this.logger.warn(`Worker not found for id/userId: ${idOrUserId}`);
            return {
                workerId: idOrUserId,
                totalScore: 0,
                qualityScore: 0,
                completionScore: 0,
                reliabilityScore: 0,
                ratingScore: 0,
                recentPerformanceScore: 0,
                experienceScore: 0,
                breakdown: {
                    quality: 0,
                    completion: 0,
                    reliability: 0,
                    rating: 0,
                    recent: 0,
                    experience: 0,
                },
            };
        }

        const score = await this.calculator.calculate(worker.id, worker);

        // Persist to worker_scores table
        try {
            await this.scoreRepo.upsert(worker.id, {
                totalScore: score.totalScore,
                qualityScore: score.qualityScore,
                completionScore: score.completionScore,
                reliabilityScore: score.reliabilityScore,
                ratingScore: score.ratingScore,
                recentPerformanceScore: score.recentPerformanceScore,
                experienceScore: score.experienceScore,
                breakdown: score.breakdown,
            });
            this.logger.log(`✅ Worker score persisted for worker ${worker.id} (user ${worker.userId}): totalScore=${score.totalScore}`);
        } catch (err) {
            this.logger.error(`Failed to persist worker score for ${worker.id}: ${err.message}`, err.stack);
        }

        return score;
    }

    async calculateBatchScores(workerIds: string[], preloadedWorkers?: any[]): Promise<Map<string, WorkerScore>> {
        const scores = new Map<string, WorkerScore>();
        const chunkSize = 50;

        for (let i = 0; i < workerIds.length; i += chunkSize) {
            const chunk = workerIds.slice(i, i + chunkSize);
            const chunkPromises = chunk.map(async (workerId) => {
                const worker = preloadedWorkers ? preloadedWorkers.find(w => w.id === workerId || w.userId === workerId) : undefined;
                try {
                    const score = await this.calculator.calculate(workerId, worker);
                    scores.set(workerId, score);

                    // Persist batch calculation
                    const canonicalId = worker?.id || workerId;
                    await this.scoreRepo.upsert(canonicalId, {
                        totalScore: score.totalScore,
                        qualityScore: score.qualityScore,
                        completionScore: score.completionScore,
                        reliabilityScore: score.reliabilityScore,
                        ratingScore: score.ratingScore,
                        recentPerformanceScore: score.recentPerformanceScore,
                        experienceScore: score.experienceScore,
                        breakdown: score.breakdown,
                    }).catch(err => {
                        this.logger.warn(`Batch score persist failed for ${canonicalId}: ${err.message}`);
                    });
                } catch (e) {
                    this.logger.error(`Failed to calculate score for worker ${workerId}`, e);
                }
            });
            await Promise.all(chunkPromises);
        }

        return scores;
    }

    async recalculateScore(idOrUserId: string): Promise<WorkerScore> {
        // Force recalculation and persistence
        return this.calculateWorkerScore(idOrUserId);
    }
}
