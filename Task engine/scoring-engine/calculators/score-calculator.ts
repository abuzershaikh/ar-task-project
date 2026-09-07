import { Injectable } from '@nestjs/common';
import { WorkerRepository } from '../../shared/database/repositories/worker.repository';
import { TaskRepository } from '../../shared/database/repositories/task.repository';
import { WorkerScore, DEFAULT_SCORE_WEIGHTS } from '../types/worker-score';

/**
 * Worker ka overall performance score calculate karta hai
 * 
 * NEW FORMULA:
 *   Completion       35%
 *   Quality          25%
 *   Reliability      20%
 *   Rating           10%
 *   Experience       10%
 *   ─────────────────────
 *   Total            100%
 * 
 * Rules:
 * - 0 tasks = 0 score
 * - Score always clamped to 0-100
 * - Activity is NOT part of score (hard eligibility gate)
 * - Score preserved even when inactive
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

        // NEW WORKER RULE: 0 tasks = starter score 60 (Normal priority ⭐⭐⭐)
        // So new workers can receive initial tasks. Real score kicks in after first task.
        // Without this, new workers would have score 0 < min threshold 40 = no tasks ever.
        if (completed === 0 && rejected === 0) {
            return {
                workerId: worker.id,
                totalScore: 60,
                completionScore: 0,
                qualityScore: 0,
                reliabilityScore: 0,
                ratingScore: 0,
                experienceScore: 0,
                breakdown: {
                    completion: 0,
                    quality: 0,
                    reliability: 0,
                    rating: 0,
                    experience: 0,
                },
            };
        }

        // Completion Score (35%) — task completion rate
        const completionScore = this.calculateCompletionScore(worker);

        // Quality Score (25%) — buyer rating-based quality (DISTINCT from completion)
        const qualityScore = this.calculateQualityScore(worker);

        // Reliability Score (20%) — low rejection/expiry rate
        const reliabilityScore = this.calculateReliabilityScore(worker);

        // Rating Score (10%) — average buyer rating normalized to 0-100
        const ratingScore = this.calculateRatingScore(worker);

        // Experience Score (10%) — task volume tiers
        const experienceScore = this.calculateExperienceScore(worker);

        // Performance points adjustment (rejection penalties affect score)
        const performanceAdjustment = this.calculatePerformanceAdjustment(worker);

        // Total weighted score with performance adjustment
        let totalScore =
            completionScore * DEFAULT_SCORE_WEIGHTS.completion +
            qualityScore * DEFAULT_SCORE_WEIGHTS.quality +
            reliabilityScore * DEFAULT_SCORE_WEIGHTS.reliability +
            ratingScore * DEFAULT_SCORE_WEIGHTS.rating +
            experienceScore * DEFAULT_SCORE_WEIGHTS.experience +
            performanceAdjustment;

        // CLAMP to 0-100 — score kabhi bhi bounds se bahar nahi jayega
        totalScore = Math.min(100, Math.max(0, totalScore));

        return {
            workerId: worker.id,
            totalScore: Math.round(totalScore * 100) / 100,
            completionScore: Math.round(completionScore * 100) / 100,
            qualityScore: Math.round(qualityScore * 100) / 100,
            reliabilityScore: Math.round(reliabilityScore * 100) / 100,
            ratingScore: Math.round(ratingScore * 100) / 100,
            experienceScore: Math.round(experienceScore * 100) / 100,
            breakdown: {
                completion: completionScore,
                quality: qualityScore,
                reliability: reliabilityScore,
                rating: ratingScore,
                experience: experienceScore,
            },
        };
    }

    /**
     * Completion Score (35% weight)
     * Task completion rate: completed / total tasks
     * Higher completion = higher score
     */
    private calculateCompletionScore(worker: any): number {
        const completed = Number(worker.totalTasksCompleted || 0);
        const rejected = Number(worker.totalTasksRejected || 0);
        const total = completed + rejected;
        if (total === 0) return 0;
        return (completed / total) * 100;
    }

    /**
     * Quality Score (25% weight)
     * Based on buyer's average rating for this worker's completed tasks
     * This is DISTINCT from completion — measures HOW WELL tasks were done
     * 
     * Uses averageRating (0-5 scale) combined with success rate
     * A worker who completes 100% but gets 2/5 ratings should score lower
     * than one who completes 90% but gets 4.5/5 ratings
     */
    private calculateQualityScore(worker: any): number {
        const avgRating = Number(worker.averageRating || 0);
        const completed = Number(worker.totalTasksCompleted || 0);
        const rejected = Number(worker.totalTasksRejected || 0);
        const total = completed + rejected;

        if (total === 0 || completed === 0) return 0;

        // If we have ratings, use them as primary quality indicator
        if (avgRating > 0) {
            // Rating component (0-5 → 0-100)
            const ratingComponent = (avgRating / 5) * 100;

            // Success rate component
            const successRate = (completed / total) * 100;

            // Quality = 70% rating-based + 30% success-based
            return Math.min(100, (ratingComponent * 0.70) + (successRate * 0.30));
        }

        // Fallback if no ratings yet: use success rate with a penalty
        // Workers without ratings get max 70% quality to encourage getting rated
        const successRate = (completed / total) * 100;
        return Math.min(70, successRate * 0.70);
    }

    /**
     * Reliability Score (20% weight)
     * How reliable is this worker? Low rejection = high reliability
     * Also factors in performance points (penalty system)
     */
    private calculateReliabilityScore(worker: any): number {
        const completed = Number(worker.totalTasksCompleted || 0);
        const rejected = Number(worker.totalTasksRejected || 0);
        const total = completed + rejected;
        if (total === 0) return 0;

        const rejectionRate = rejected / total;

        // Base reliability from rejection rate
        let reliability = Math.max(0, 100 - (rejectionRate * 100));

        // Performance points factor — negative points reduce reliability further
        const perfPoints = Number(worker.performancePoints || 0);
        if (perfPoints < 0) {
            // Each negative point reduces reliability by 2%, capped at -40%
            const pointPenalty = Math.min(40, Math.abs(perfPoints) * 2);
            reliability = Math.max(0, reliability - pointPenalty);
        }

        return reliability;
    }

    /**
     * Rating Score (10% weight)
     * Pure average rating from buyers (0-5 scale → 0-100)
     */
    private calculateRatingScore(worker: any): number {
        const avgRating = Number(worker.averageRating || 0);
        if (avgRating <= 0) return 0;
        return Math.min(100, (avgRating / 5) * 100);
    }

    /**
     * Experience Score (10% weight)
     * Based on total tasks completed — tiered system
     */
    private calculateExperienceScore(worker: any): number {
        const completed = Number(worker.totalTasksCompleted || 0);
        if (completed === 0) return 0;
        if (completed < 5) return 20;
        if (completed < 20) return 40;
        if (completed < 50) return 60;
        if (completed < 100) return 80;
        return 100;
    }

    /**
     * Performance adjustment based on performance points
     * +1 per completed task, -3 per rejected, -5 per expired
     * This adds/subtracts from final score (before clamping)
     */
    private calculatePerformanceAdjustment(worker: any): number {
        const perfPoints = Number(worker.performancePoints || 0);
        if (perfPoints >= 0) return 0;

        // Negative performance points reduce total score
        // Each -1 point = -0.5 total score reduction, max -15
        return Math.max(-15, perfPoints * 0.5);
    }
}
