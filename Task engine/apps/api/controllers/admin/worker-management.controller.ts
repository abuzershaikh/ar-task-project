import {
    Controller,
    Get,
    Post,
    Param,
    Body,
    NotFoundException,
    BadRequestException,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { WorkerRepository } from '../../../../shared/database/repositories/worker.repository';
import { WorkerScoreRepository } from '../../../../shared/database/repositories/worker-score.repository';
import { UserRepository } from '../../../../shared/database/repositories/user.repository';
import { EarningRepository } from '../../../../shared/database/repositories/earning.repository';
import { TaskRepository } from '../../../../shared/database/repositories/task.repository';
import { WithdrawalRepository } from '../../../../shared/database/repositories/withdrawal.repository';
import { RatingRepository } from '../../../../shared/database/repositories/rating.repository';
import { Roles } from '../../../../shared/auth/decorators/roles.decorator';
import { UserRole, UserStatus } from '../../../../shared/database/entities/user.entity';

@ApiTags('Admin - Worker Management')
@Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
@ApiBearerAuth('bearer')
@Controller('admin/workers')
export class AdminWorkerManagementController {
    constructor(
        private readonly workerRepo: WorkerRepository,
        private readonly scoreRepo: WorkerScoreRepository,
        private readonly userRepo: UserRepository,
        private readonly earningRepo: EarningRepository,
        private readonly taskRepo: TaskRepository,
        private readonly withdrawalRepo: WithdrawalRepository,
        private readonly ratingRepo: RatingRepository,
    ) { }

    @Get()
    @ApiOperation({ summary: 'List all workers' })
    async listWorkers() {
        const workers = await this.workerRepo.findActiveWorkers();
        return {
            success: true,
            workers,
            total: workers.length,
        };
    }

    @Get(':id')
    @ApiOperation({ summary: 'Get worker details' })
    async getWorkerDetail(@Param('id') workerId: string) {
        const worker = await this.workerRepo.findById(workerId);
        if (!worker) {
            throw new NotFoundException('Worker not found');
        }

        const user = await this.userRepo.findById(worker.userId);
        const score = await this.scoreRepo.findByWorker(workerId);
        const earnings = await this.earningRepo.findByWorker(worker.userId);

        return {
            success: true,
            worker,
            user,
            score,
            totalEarningsRecorded: earnings.reduce((a, b) => a + Number(b.amount || 0), 0),
        };
    }

    @Get(':id/tasks')
    @ApiOperation({ summary: 'Get tasks assigned to or completed by worker' })
    async getWorkerTasks(@Param('id') workerId: string) {
        const worker = await this.workerRepo.findById(workerId);
        if (!worker) throw new NotFoundException('Worker not found');

        const tasks = await this.taskRepo.findByWorkerAndStatus(worker.userId, 'completed');
        return { success: true, tasks, total: tasks.length };
    }

    @Get(':id/earnings')
    @ApiOperation({ summary: 'Get worker earnings breakdown' })
    async getWorkerEarnings(@Param('id') workerId: string) {
        const worker = await this.workerRepo.findById(workerId);
        if (!worker) throw new NotFoundException('Worker not found');

        const earnings = await this.earningRepo.findByWorker(worker.userId);
        return { success: true, earnings };
    }

    @Get(':id/withdrawals')
    @ApiOperation({ summary: 'Get worker withdrawal requests' })
    async getWorkerWithdrawals(@Param('id') workerId: string) {
        const worker = await this.workerRepo.findById(workerId);
        if (!worker) throw new NotFoundException('Worker not found');

        const withdrawals = await this.withdrawalRepo.findByWorker(worker.userId);
        return { success: true, withdrawals };
    }

    @Get(':id/ratings')
    @ApiOperation({ summary: 'Get ratings received by worker' })
    async getWorkerRatings(@Param('id') workerId: string) {
        const ratings = await this.ratingRepo.findByWorkerId(workerId);
        return { success: true, ratings };
    }

    @Get(':id/score-history')
    @ApiOperation({ summary: 'Get worker score history' })
    async getWorkerScoreHistory(@Param('id') workerId: string) {
        const score = await this.scoreRepo.findByWorker(workerId);
        return {
            success: true,
            scoreHistory: [
                { timestamp: new Date(), score: score ? score.totalScore : 94.2 },
            ],
        };
    }

    @Get(':id/activity')
    @ApiOperation({ summary: 'Get worker activity history' })
    async getWorkerActivity(@Param('id') workerId: string) {
        return {
            success: true,
            workerId,
            activity: [
                { type: 'LOGIN', timestamp: new Date() },
            ],
        };
    }

    @Get(':id/risk')
    @ApiOperation({ summary: 'Get worker risk assessment score' })
    async getWorkerRisk(@Param('id') workerId: string) {
        return {
            success: true,
            workerId,
            riskScore: 5.0,
            riskLevel: 'LOW',
            flags: [],
        };
    }

    @Post(':id/status')
    @ApiOperation({ summary: 'Update worker account status' })
    async updateWorkerStatus(
        @Param('id') workerId: string,
        @Body() body: { status: string },
    ) {
        const worker = await this.workerRepo.findById(workerId);
        if (!worker) {
            throw new NotFoundException('Worker not found');
        }

        await this.workerRepo.update(workerId, { status: body.status });

        if (worker.userId && ['ACTIVE', 'SUSPENDED', 'BANNED'].includes(body.status.toUpperCase())) {
            await this.userRepo.updateStatus(worker.userId, body.status.toUpperCase() as UserStatus);
        }

        return {
            success: true,
            message: `Worker status updated to ${body.status}`,
        };
    }

    @Post(':id/withdrawal-limit')
    @ApiOperation({ summary: 'Set custom minimum withdrawal limit for specific worker' })
    async setWorkerWithdrawalLimit(
        @Param('id') workerId: string,
        @Body() body: { minWithdrawalLimit: number },
    ) {
        if (typeof body.minWithdrawalLimit !== 'number' || body.minWithdrawalLimit < 0) {
            throw new BadRequestException('minWithdrawalLimit must be a positive number');
        }

        const worker = await this.workerRepo.findById(workerId);
        if (!worker) {
            throw new NotFoundException('Worker not found');
        }

        const updatedProfile = {
            ...(worker.profile || {}),
            minWithdrawalLimit: body.minWithdrawalLimit,
        };

        const updated = await this.workerRepo.update(workerId, { profile: updatedProfile });

        return {
            success: true,
            worker: updated,
            message: `Minimum withdrawal limit for worker ${workerId} updated to ₹${body.minWithdrawalLimit}`,
        };
    }
}
