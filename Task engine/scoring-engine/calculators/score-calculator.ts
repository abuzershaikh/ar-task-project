import { Injectable } from '@nestjs/common';
import { WorkerRepository } from '../../shared/database/repositories/worker.repository';
import { TaskRepository } from '../../shared/database/repositories/task.repository';
import { WorkerScore } from '../types/worker-score';

/**
 * Worker ka overall performance score calculate karta hai
 */
@Injectable()
export class ScoreCalculator {
    constructor(
        private readonly workerRepo: WorkerRepository,
        private readonly taskRepo: TaskRepository,
    ) { }

    async calculate(workerId: string): Promise<WorkerScore> {
        const worker = await this.workerRepo.findById(workerId);

        if (!worker) {
            throw new Error('Worker not found');
        }

        // Quality Score (30%)
        const qualityScore = this.calculateQualityScore(worker);

        // Completion Score (20%)
        const completionScore = this.calculateCompletionScore(worker);

        // Reliability Score (15%)
        const reliabilityScore = this.calculateReliabilityScore(worker);

        // Rating Score (20%)
        const ratingScore = this.calculateRatingScore(worker);

        // Recent Performance Score (10%)
        const recentScore = await this.calculateRecentPerformance(workerId);

        // Experience Score (5%)
        const experienceScore = this.calculateExperienceScore(worker);

        // Total weighted score
        const totalScore =
            qualityScore * 0.30 +
            completionScore * 0.20 +
            reliabilityScore * 0.15 +
            ratingScore * 0.20 +
            recentScore * 0.10 +
            experienceScore * 0.05;

        return {
            workerId,
            totalScore: Math.round(totalScore * 100) / 100,
            qualityScore,
            completionScore,
            reliabilityScore,
            ratingScore,
            recentPerformanceScore: recentScore,
            experienceScore,
            breakdown: {
                quality: qualityScore,
                completion: completionScore,
                reliability: reliabilityScore,
                rating: ratingScore,
                recent: recentScore,
                experience: experienceScore,
            },
        };
    }

    private calculateQualityScore(worker: any): number {
        // Success rate based quality
        const successRate = worker.successRate || 0;
        return Math.min(100, successRate);
    }

    private calculateCompletionScore(worker: any): number {
        const completed = worker.totalTasksCompleted || 0;
        const rejected = worker.totalTasksRejected || 0;
        const total = completed + rejected;

        if (total === 0) return 0;

        return (completed / total) * 100;
    }

    private calculateReliabilityScore(worker: any): number {
        // Based on rejection rate
        const completed = worker.totalTasksCompleted || 0;
        const rejected = worker.totalTasksRejected || 0;
        const total = completed + rejected;

        if (total === 0) return 100;

        const rejectionRate = rejected / total;
        return Math.max(0, 100 - (rejectionRate * 100));
    }

    private calculateRatingScore(worker: any): number {
        const avgRating = worker.averageRating || 0;
        return (avgRating / 5) * 100;
    }

    private async calculateRecentPerformance(workerId: string): Promise<number> {
        // Last 10 tasks performance
        // TODO: Implement detailed recent performance
        return 80; // Placeholder
    }

    private calculateExperienceScore(worker: any): number {
        const completed = worker.totalTasksCompleted || 0;

        if (completed === 0) return 0;
        if (completed < 10) return 20;
        if (completed < 50) return 40;
        if (completed < 100) return 60;
        if (completed < 500) return 80;

        return 100;
    }
}
