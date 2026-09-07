import { Injectable } from '@nestjs/common';
import { WorkerRepository } from '../../shared/database/repositories/worker.repository';
import { TaskRepository } from '../../shared/database/repositories/task.repository';
import { WorkerScore } from '../types/worker-score';

/**
 * Worker ka overall performance score calculate karta hai
 * Rule: 0 tasks = 0 score. Real tasks = real score.
 */
@Injectable()
export class ScoreCalculator {
    constructor(
        private readonly workerRepo: WorkerRepository,
        private readonly taskRepo: TaskRepository,
    ) { }

    async calculate(workerId: string, preloadedWorker?: any): Promise<WorkerScore> {
        const worker = preloadedWorker || await this.workerRepo.findWorker(workerId);

        if (!worker) {
            throw new Error(`Worker not found: ${workerId}`);
        }

        const completed = Number(worker.totalTasksCompleted || 0);
        const rejected = Number(worker.totalTasksRejected || 0);

        // If worker has no task activity at all, real score is strictly 0
        if (completed === 0 && rejected === 0) {
            return {
                workerId: worker.id,
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

        // Quality Score (30%)
        const qualityScore = this.calculateQualityScore(worker);

        // Completion Score (20%)
        const completionScore = this.calculateCompletionScore(worker);

        // Reliability Score (15%)
        const reliabilityScore = this.calculateReliabilityScore(worker);

        // Rating Score (20%)
        const ratingScore = this.calculateRatingScore(worker);

        // Recent Performance Score (10%)
        const recentScore = await this.calculateRecentPerformance(worker.id, worker);

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
            workerId: worker.id,
            totalScore: Math.round(totalScore * 100) / 100,
            qualityScore: Math.round(qualityScore * 100) / 100,
            completionScore: Math.round(completionScore * 100) / 100,
            reliabilityScore: Math.round(reliabilityScore * 100) / 100,
            ratingScore: Math.round(ratingScore * 100) / 100,
            recentPerformanceScore: Math.round(recentScore * 100) / 100,
            experienceScore: Math.round(experienceScore * 100) / 100,
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
        const completed = Number(worker.totalTasksCompleted || 0);
        const rejected = Number(worker.totalTasksRejected || 0);
        const total = completed + rejected;
        if (total === 0) return 0;
        return (completed / total) * 100;
    }

    private calculateCompletionScore(worker: any): number {
        const completed = Number(worker.totalTasksCompleted || 0);
        const rejected = Number(worker.totalTasksRejected || 0);
        const total = completed + rejected;
        if (total === 0) return 0;
        return (completed / total) * 100;
    }

    private calculateReliabilityScore(worker: any): number {
        const completed = Number(worker.totalTasksCompleted || 0);
        const rejected = Number(worker.totalTasksRejected || 0);
        const total = completed + rejected;
        if (total === 0) return 0;
        const rejectionRate = rejected / total;
        return Math.max(0, 100 - (rejectionRate * 100));
    }

    private calculateRatingScore(worker: any): number {
        const avgRating = Number(worker.averageRating || 0);
        if (avgRating <= 0) return 0;
        return Math.min(100, (avgRating / 5) * 100);
    }

    private async calculateRecentPerformance(workerId: string, worker?: any): Promise<number> {
        const completed = Number(worker?.totalTasksCompleted || 0);
        const rejected = Number(worker?.totalTasksRejected || 0);
        const total = completed + rejected;
        if (total === 0) return 0;
        const rate = (completed / total) * 100;
        return Math.min(100, Math.max(0, Math.round(rate)));
    }

    private calculateExperienceScore(worker: any): number {
        const completed = Number(worker.totalTasksCompleted || 0);
        if (completed === 0) return 0;
        if (completed < 5) return 20;
        if (completed < 20) return 40;
        if (completed < 50) return 60;
        if (completed < 100) return 80;
        return 100;
    }
}
