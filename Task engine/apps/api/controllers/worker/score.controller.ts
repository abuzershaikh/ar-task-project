import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { WorkerRepository } from '../../../../shared/database/repositories/worker.repository';
import { WorkerScoreRepository } from '../../../../shared/database/repositories/worker-score.repository';
import { ScoringEngineService } from '../../../../scoring-engine/scoring.service';
import { Roles } from '../../../../shared/auth/decorators/roles.decorator';
import { CurrentUser } from '../../../../shared/auth/decorators/current-user.decorator';
import { UserRole, User } from '../../../../shared/database/entities/user.entity';
import { MIN_SCORE_THRESHOLD } from '../../../../scoring-engine/types/worker-score';

@ApiTags('Worker - Quality Score & Stats')
@Roles(UserRole.WORKER)
@ApiBearerAuth('bearer')
@Controller('worker/score')
export class WorkerScoreController {
    constructor(
        private readonly workerRepo: WorkerRepository,
        private readonly scoreRepo: WorkerScoreRepository,
        private readonly scoringEngine: ScoringEngineService,
    ) { }

    /**
     * 5-tier priority system
     * Score 90-100 → ⭐⭐⭐⭐⭐ CRITICAL
     * Score 75-89  → ⭐⭐⭐⭐   HIGH
     * Score 60-74  → ⭐⭐⭐     NORMAL
     * Score 40-59  → ⭐⭐       LOW
     * Score 0-39   → ⭐         VERY_LOW (no auto tasks)
     */
    private determinePriority(score: number): { level: string; stars: number; label: string } {
        if (score >= 90) return { level: 'CRITICAL', stars: 5, label: '⭐⭐⭐⭐⭐ Sabse pehle / high-value tasks' };
        if (score >= 75) return { level: 'HIGH', stars: 4, label: '⭐⭐⭐⭐ High priority' };
        if (score >= 60) return { level: 'NORMAL', stars: 3, label: '⭐⭐⭐ Normal tasks' };
        if (score >= 40) return { level: 'LOW', stars: 2, label: '⭐⭐ Low priority' };
        return { level: 'VERY_LOW', stars: 1, label: '⭐ Very low priority / limited tasks' };
    }

    private determineTier(completed: number, score: number): string {
        if (completed === 0) return 'NEW';
        if (completed >= 25 && score >= 90) return 'GOLD';
        if (completed >= 10 && score >= 75) return 'SILVER';
        return 'BRONZE';
    }

    @Get()
    @ApiOperation({ summary: 'Get worker score, priority, activity status, and component quality breakdown' })
    async getWorkerScore(@CurrentUser() user: User) {
        const worker = await this.workerRepo.findWorker(user.id);
        if (!worker) {
            return {
                success: true,
                score: {
                    overallScore: 0,
                    breakdown: { completion: 0, quality: 0, reliability: 0, rating: 0, experience: 0 },
                    priority: this.determinePriority(0),
                    workerTier: 'NEW',
                    activityStatus: 'INACTIVE',
                    isEligibleForTasks: false,
                    performancePoints: 0,
                    updatedAt: new Date(),
                },
            };
        }

        const completed = Number(worker.totalTasksCompleted || 0);
        const rejected = Number(worker.totalTasksRejected || 0);

        // New worker: starter score 50
        if (completed === 0 && rejected === 0) {
            const activityStatus = this.workerRepo.getActivityStatus(worker);
            return {
                success: true,
                score: {
                    overallScore: 60,
                    breakdown: {
                        completion: 0,
                        quality: 0,
                        reliability: 0,
                        rating: 0,
                        experience: 0,
                    },
                    priority: this.determinePriority(50),
                    workerTier: 'NEW',
                    activityStatus,
                    isEligibleForTasks: this.workerRepo.isActivityEligible(worker) && !this.workerRepo.isOnCooldown(worker),
                    performancePoints: Number(worker.performancePoints || 0),
                    onCooldown: this.workerRepo.isOnCooldown(worker),
                    cooldownUntil: worker.taskCooldownUntil || null,
                    updatedAt: worker.updatedAt || new Date(),
                    message: 'New worker — starter score 60. Complete tasks to build your real score!',
                },
            };
        }

        let scoreRecord = await this.scoreRepo.findByWorker(worker.id);
        if (!scoreRecord) {
            scoreRecord = (await this.scoringEngine.calculateWorkerScore(worker.id)) as any;
        }

        const overallScore = scoreRecord ? Number(scoreRecord.totalScore || 0) : 0;
        const breakdown = scoreRecord?.breakdown || {
            completion: Number(scoreRecord?.completionScore || 0),
            quality: Number(scoreRecord?.qualityScore || 0),
            reliability: Number(scoreRecord?.reliabilityScore || 0),
            rating: Number(scoreRecord?.ratingScore || 0),
            experience: Number(scoreRecord?.experienceScore || 0),
        };

        const activityStatus = this.workerRepo.getActivityStatus(worker);
        const isActivityEligible = this.workerRepo.isActivityEligible(worker);
        const onCooldown = this.workerRepo.isOnCooldown(worker);

        return {
            success: true,
            score: {
                overallScore,
                breakdown,
                priority: this.determinePriority(overallScore),
                workerTier: this.determineTier(completed, overallScore),
                activityStatus,
                isEligibleForTasks: isActivityEligible && overallScore >= MIN_SCORE_THRESHOLD && !onCooldown,
                performancePoints: Number(worker.performancePoints || 0),
                onCooldown,
                cooldownUntil: worker.taskCooldownUntil || null,
                lastActiveAt: worker.lastActiveAt || null,
                updatedAt: scoreRecord?.updatedAt || new Date(),
            },
        };
    }

    @Get('history')
    @ApiOperation({ summary: 'Get worker score historical timeline' })
    async getScoreHistory(@CurrentUser() user: User) {
        const worker = await this.workerRepo.findWorker(user.id);
        if (!worker) {
            return {
                success: true,
                history: [{ timestamp: new Date(), overallScore: 0 }],
            };
        }

        const completed = Number(worker.totalTasksCompleted || 0);
        if (completed === 0) {
            return {
                success: true,
                history: [{ timestamp: worker.createdAt || new Date(), overallScore: 60 }], // starter score
            };
        }

        const scoreRecord = await this.scoreRepo.findByWorker(worker.id);
        const currentScore = scoreRecord ? Number(scoreRecord.totalScore || 0) : 0;

        return {
            success: true,
            history: [
                { timestamp: worker.createdAt || new Date(Date.now() - 7 * 86400000), overallScore: 60 }, // started at 60
                { timestamp: scoreRecord?.updatedAt || new Date(), overallScore: currentScore },
            ],
        };
    }
}
