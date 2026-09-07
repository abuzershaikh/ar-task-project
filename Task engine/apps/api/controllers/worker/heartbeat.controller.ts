import { Controller, Post, Get } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { WorkerRepository } from '../../../../shared/database/repositories/worker.repository';
import { WorkerScoreRepository } from '../../../../shared/database/repositories/worker-score.repository';
import { Roles } from '../../../../shared/auth/decorators/roles.decorator';
import { CurrentUser } from '../../../../shared/auth/decorators/current-user.decorator';
import { UserRole, User } from '../../../../shared/database/entities/user.entity';

/**
 * Worker Heartbeat Controller
 * 
 * Worker app se heartbeat receive karta hai.
 * Jab worker app open kare, meaningful activity kare, ya periodic heartbeat bheje:
 * 1. lastActiveAt = NOW()
 * 2. status = ACTIVE (if was inactive)
 * 3. Cooldown clear (if expired)
 * 4. Returns current activity status + score
 * 
 * Worker active hote hi score ke basis par dobara matching milegi.
 */
@ApiTags('Worker - Heartbeat & Activity')
@Roles(UserRole.WORKER)
@ApiBearerAuth('bearer')
@Controller('worker/heartbeat')
export class WorkerHeartbeatController {
    constructor(
        private readonly workerRepo: WorkerRepository,
        private readonly scoreRepo: WorkerScoreRepository,
    ) { }

    /**
     * POST /worker/heartbeat
     * Worker app se heartbeat — lastActiveAt update karta hai
     * 
     * Call this on:
     * - App open/foreground
     * - Task view/interaction
     * - Periodic background ping (every 15-30 min)
     */
    @Post()
    @ApiOperation({ summary: 'Send worker heartbeat to update activity status' })
    async sendHeartbeat(@CurrentUser() user: User) {
        const worker = await this.workerRepo.findWorker(user.id);
        if (!worker) {
            return {
                success: false,
                message: 'Worker profile not found',
            };
        }

        const previousStatus = this.workerRepo.getActivityStatus(worker);

        // 1. Update lastActiveAt = NOW()
        await this.workerRepo.updateLastActiveAt(worker.id);

        // 2. Clear expired cooldown (if any)
        if (worker.taskCooldownUntil && new Date(worker.taskCooldownUntil).getTime() <= Date.now()) {
            await this.workerRepo.clearCooldown(worker.id);
        }

        // 3. Get current score
        const scoreRecord = await this.scoreRepo.findByWorker(worker.id);
        const totalScore = scoreRecord ? Number(scoreRecord.totalScore || 0) : 0;

        // 4. Determine new status
        const newStatus = 'ACTIVE'; // Just sent heartbeat, so definitely active

        const wasInactive = previousStatus === 'INACTIVE';

        return {
            success: true,
            heartbeat: {
                previousStatus,
                currentStatus: newStatus,
                reactivated: wasInactive,
                lastActiveAt: new Date(),
                score: totalScore,
                performancePoints: Number(worker.performancePoints || 0),
                onCooldown: this.workerRepo.isOnCooldown(worker),
                cooldownUntil: worker.taskCooldownUntil || null,
                message: wasInactive
                    ? `Welcome back! You are now ACTIVE with score ${totalScore}. Task distribution resumed.`
                    : `Heartbeat received. Status: ACTIVE, Score: ${totalScore}`,
            },
        };
    }

    /**
     * GET /worker/heartbeat/status
     * Worker ka current activity status check karo (without updating)
     */
    @Get('status')
    @ApiOperation({ summary: 'Get worker activity status without updating heartbeat' })
    async getActivityStatus(@CurrentUser() user: User) {
        const worker = await this.workerRepo.findWorker(user.id);
        if (!worker) {
            return {
                success: false,
                message: 'Worker profile not found',
            };
        }

        const activityStatus = this.workerRepo.getActivityStatus(worker);
        const scoreRecord = await this.scoreRepo.findByWorker(worker.id);
        const totalScore = scoreRecord ? Number(scoreRecord.totalScore || 0) : 0;

        return {
            success: true,
            activity: {
                status: activityStatus,
                lastActiveAt: worker.lastActiveAt || null,
                score: totalScore,
                performancePoints: Number(worker.performancePoints || 0),
                isEligibleForTasks: this.workerRepo.isActivityEligible(worker) && totalScore >= 40,
                onCooldown: this.workerRepo.isOnCooldown(worker),
                cooldownUntil: worker.taskCooldownUntil || null,
            },
        };
    }
}
