import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { WorkerRepository } from '../../../../shared/database/repositories/worker.repository';
import { WorkerScoreRepository } from '../../../../shared/database/repositories/worker-score.repository';
import { ScoringEngineService } from '../../../../scoring-engine/scoring.service';
import { Roles } from '../../../../shared/auth/decorators/roles.decorator';
import { CurrentUser } from '../../../../shared/auth/decorators/current-user.decorator';
import { UserRole, User } from '../../../../shared/database/entities/user.entity';

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

    private determineTier(completed: number, score: number): string {
        if (completed === 0) return 'NEW';
        if (completed >= 25 && score >= 90) return 'GOLD';
        if (completed >= 10 && score >= 75) return 'SILVER';
        return 'BRONZE';
    }

    @Get()
    @ApiOperation({ summary: 'Get worker score and component quality breakdown' })
    async getWorkerScore(@CurrentUser() user: User) {
        const worker = await this.workerRepo.findWorker(user.id);
        if (!worker) {
            return {
                success: true,
                score: {
                    overallScore: 0,
                    breakdown: { quality: 0, completion: 0, reliability: 0, rating: 0, recentPerformance: 0, experience: 0 },
                    workerTier: 'NEW',
                    updatedAt: new Date(),
                },
            };
        }

        const completed = Number(worker.totalTasksCompleted || 0);
        const rejected = Number(worker.totalTasksRejected || 0);

        // Strict rule: 0 completed tasks = 0 score, NEW tier
        if (completed === 0 && rejected === 0) {
            return {
                success: true,
                score: {
                    overallScore: 0,
                    breakdown: {
                        quality: 0,
                        completion: 0,
                        reliability: 0,
                        rating: 0,
                        recentPerformance: 0,
                        experience: 0,
                    },
                    workerTier: 'NEW',
                    updatedAt: worker.updatedAt || new Date(),
                },
            };
        }

        let scoreRecord = await this.scoreRepo.findByWorker(worker.id);
        if (!scoreRecord) {
            scoreRecord = (await this.scoringEngine.calculateWorkerScore(worker.id)) as any;
        }

        const overallScore = scoreRecord ? Number(scoreRecord.totalScore || 0) : 0;
        const breakdown = scoreRecord?.breakdown || {
            quality: Number(scoreRecord?.qualityScore || 0),
            completion: Number(scoreRecord?.completionScore || 0),
            reliability: Number(scoreRecord?.reliabilityScore || 0),
            rating: Number(scoreRecord?.ratingScore || 0),
            recentPerformance: Number(scoreRecord?.recentPerformanceScore || 0),
            experience: Number(scoreRecord?.experienceScore || 0),
        };

        return {
            success: true,
            score: {
                overallScore,
                breakdown,
                workerTier: this.determineTier(completed, overallScore),
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
                history: [{ timestamp: worker.createdAt || new Date(), overallScore: 0 }],
            };
        }

        const scoreRecord = await this.scoreRepo.findByWorker(worker.id);
        const currentScore = scoreRecord ? Number(scoreRecord.totalScore || 0) : 0;

        return {
            success: true,
            history: [
                { timestamp: worker.createdAt || new Date(Date.now() - 7 * 86400000), overallScore: 0 },
                { timestamp: scoreRecord?.updatedAt || new Date(), overallScore: currentScore },
            ],
        };
    }
}
