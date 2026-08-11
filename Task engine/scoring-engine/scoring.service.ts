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

    async calculateBatchScores(workerIds: string[]): Promise<Map<string, WorkerScore>> {
        const scores = new Map<string, WorkerScore>();

        for (const workerId of workerIds) {
            const score = await this.calculateWorkerScore(workerId);
            scores.set(workerId, score);
        }

        return scores;
    }

    async recalculateScore(workerId: string): Promise<WorkerScore> {
        // Force recalculation
        return this.calculateWorkerScore(workerId);
    }
}
