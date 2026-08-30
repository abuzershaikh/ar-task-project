import { Controller, Get, Patch, Body, NotFoundException } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { WorkerRepository } from '../../../../shared/database/repositories/worker.repository';
import { WorkerScoreRepository } from '../../../../shared/database/repositories/worker-score.repository';
import { TaskRepository } from '../../../../shared/database/repositories/task.repository';
import { EarningRepository } from '../../../../shared/database/repositories/earning.repository';
import { RatingRepository } from '../../../../shared/database/repositories/rating.repository';
import { Roles } from '../../../../shared/auth/decorators/roles.decorator';
import { CurrentUser } from '../../../../shared/auth/decorators/current-user.decorator';
import { UserRole, User } from '../../../../shared/database/entities/user.entity';

@ApiTags('Worker - Profile & Dashboard')
@Roles(UserRole.WORKER)
@ApiBearerAuth('bearer')
@Controller('worker')
export class WorkerProfileController {
    constructor(
        private readonly workerRepo: WorkerRepository,
        private readonly scoreRepo: WorkerScoreRepository,
        private readonly taskRepo: TaskRepository,
        private readonly earningRepo: EarningRepository,
        private readonly ratingRepo: RatingRepository,
    ) { }

    private async getOrCreateWorker(user: User) {
        let worker = await this.workerRepo.findByUserId(user.id);
        if (!worker) {
            worker = await this.workerRepo.create({
                userId: user.id,
                status: 'active',
                kycStatus: 'pending',
                profile: { fullName: user.fullName, email: user.email },
            });
        }
        return worker;
    }

    @Get('profile')
    @ApiOperation({ summary: 'Get worker profile' })
    async getProfile(@CurrentUser() user: User) {
        const worker = await this.getOrCreateWorker(user);
        const score = await this.scoreRepo.findByWorker(worker.id);

        const completed = Number(worker.totalTasksCompleted || 0);
        const rejected = Number(worker.totalTasksRejected || 0);
        const total = completed + rejected;
        const quality = total > 0 ? Math.round((completed / total) * 1000) / 10 : 98.5;
        const reliability = total > 0 ? Math.max(85, Math.round((1 - (rejected / total)) * 1000) / 10) : 99.2;
        const rating = (worker.averageRating && Number(worker.averageRating) > 0) ? Number(worker.averageRating) : 4.9;
        const overallScore = Math.round(((quality * 0.45) + (reliability * 0.35) + ((rating / 5) * 100 * 0.20)) * 10) / 10;

        const effectiveScore = score ? {
            totalScore: score.totalScore,
            breakdown: score.breakdown,
            updatedAt: score.updatedAt,
        } : {
            totalScore: overallScore,
            breakdown: {
                quality,
                completion: total > 0 ? 100 : 98.0,
                reliability,
                rating,
                recentPerformance: 95.0,
                experience: Math.min(100, 70 + (completed * 2)),
            },
            updatedAt: new Date(),
        };

        return {
            success: true,
            worker: {
                id: worker.id,
                userId: user.id,
                email: user.email,
                fullName: user.fullName,
                phone: user.phone,
                status: worker.status,
                kycStatus: worker.kycStatus,
                profile: worker.profile,
                preferences: worker.preferences,
                totalTasksCompleted: completed,
                totalTasksRejected: rejected,
                successRate: quality,
                averageRating: rating,
                totalEarnings: worker.totalEarnings,
                score: effectiveScore,
            },
        };
    }

    @Patch('profile')
    @ApiOperation({ summary: 'Update worker profile' })
    async updateProfile(
        @CurrentUser() user: User,
        @Body() body: { profile?: any; preferences?: any },
    ) {
        const worker = await this.getOrCreateWorker(user);

        const updated = await this.workerRepo.update(worker.id, {
            profile: body.profile ? { ...worker.profile, ...body.profile } : worker.profile,
            preferences: body.preferences ? { ...worker.preferences, ...body.preferences } : worker.preferences,
        });

        return {
            success: true,
            worker: updated,
            message: 'Profile updated successfully',
        };
    }

    @Get('dashboard')
    @ApiOperation({ summary: 'Get worker dashboard overview' })
    async getDashboard(@CurrentUser() user: User) {
        const worker = await this.getOrCreateWorker(user);
        const assignedTasks = await this.taskRepo.findByWorkerAndStatus(user.id, 'assigned');
        const activeTasks = await this.taskRepo.findByWorkerAndStatus(user.id, 'in_progress');
        const totalEarnings = await this.earningRepo.getTotalEarnings(user.id);
        const ratingSummary = await this.ratingRepo.getWorkerRatingSummary(worker.id);

        return {
            success: true,
            dashboard: {
                workerId: worker.id,
                status: worker.status,
                kycStatus: worker.kycStatus,
                assignedCount: assignedTasks.length,
                inProgressCount: activeTasks.length,
                totalTasksCompleted: worker.totalTasksCompleted,
                totalEarnings,
                averageRating: ratingSummary.average,
                totalRatingsCount: ratingSummary.count,
            },
        };
    }

    @Get('stats')
    @ApiOperation({ summary: 'Get worker performance statistics' })
    async getStats(@CurrentUser() user: User) {
        const worker = await this.getOrCreateWorker(user);
        const score = await this.scoreRepo.findByWorker(worker.id);
        const ratingSummary = await this.ratingRepo.getWorkerRatingSummary(worker.id);

        return {
            success: true,
            stats: {
                totalTasksCompleted: worker.totalTasksCompleted,
                totalTasksRejected: worker.totalTasksRejected,
                successRate: worker.successRate,
                averageRating: ratingSummary.average,
                totalRatingsCount: ratingSummary.count,
                scoreBreakdown: score ? score.breakdown : null,
                totalScore: score ? score.totalScore : 0,
            },
        };
    }
}
