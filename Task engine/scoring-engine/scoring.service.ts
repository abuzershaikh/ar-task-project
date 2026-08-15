import { Injectable } from '@nestjs/common';
import { ScoreCalculator } from './calculators/score-calculator';
import { WorkerScore } from './types/worker-score';

/**
 * Scoring Engine
 * Worker ka performance score calculate karta hai
 */
@Injectable()
export class ScoringEngineService {
    constructor(private readonly calculator: ScoreCalculator) { }

    async calculateWorkerScore(workerId: string): Promise<WorkerScore> {
        const score = await this.calculator.calculate(workerId);
        return score;
    }

    async calculateBatchScores(workerIds: string[], preloadedWorkers?: any[]): Promise<Map<string, WorkerScore>> {
        const scores = new Map<string, WorkerScore>();
        const chunkSize = 50;

        for (let i = 0; i < workerIds.length; i += chunkSize) {
            const chunk = workerIds.slice(i, i + chunkSize);
            const chunkPromises = chunk.map(async (workerId) => {
                const worker = preloadedWorkers ? preloadedWorkers.find(w => w.id === workerId) : undefined;
                try {
                    const score = await this.calculator.calculate(workerId, worker);
                    scores.set(workerId, score);
                } catch (e) {
                    console.error(`Failed to calculate score for worker ${workerId}`, e);
                }
            });
            await Promise.all(chunkPromises);
        }

        return scores;
    }

    async recalculateScore(workerId: string): Promise<WorkerScore> {
        // Force recalculation
        return this.calculateWorkerScore(workerId);
    }
}
