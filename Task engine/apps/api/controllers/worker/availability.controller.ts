import { Controller, Get, Post, Body } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { WorkerRepository } from '../../../../shared/database/repositories/worker.repository';
import { Roles } from '../../../../shared/auth/decorators/roles.decorator';
import { CurrentUser } from '../../../../shared/auth/decorators/current-user.decorator';
import { UserRole, User } from '../../../../shared/database/entities/user.entity';

@ApiTags('Worker - Availability & Capacity')
@Roles(UserRole.WORKER)
@ApiBearerAuth('bearer')
@Controller('worker/availability')
export class WorkerAvailabilityController {
    constructor(private readonly workerRepo: WorkerRepository) { }

    private async getOrCreateWorker(userId: string) {
        let worker = await this.workerRepo.findByUserId(userId);
        if (!worker) {
            worker = await this.workerRepo.create({ userId, status: 'active', kycStatus: 'pending' });
        }
        return worker;
    }

    @Get()
    @ApiOperation({ summary: 'Get worker availability status and max concurrent task capacity' })
    async getAvailability(@CurrentUser() user: User) {
        const worker = await this.getOrCreateWorker(user.id);
        const preferences = worker.preferences || {};

        return {
            success: true,
            availability: {
                available: preferences.available !== undefined ? preferences.available : true,
                maxConcurrentTasks: preferences.maxConcurrentTasks || 5,
                currentActiveTasks: worker.totalTasksCompleted ? 1 : 0,
            },
        };
    }

    @Post()
    @ApiOperation({ summary: 'Update worker availability and concurrency preferences' })
    async updateAvailability(
        @CurrentUser() user: User,
        @Body() body: { available: boolean; maxConcurrentTasks?: number },
    ) {
        const worker = await this.getOrCreateWorker(user.id);
        const updatedPreferences = {
            ...(worker.preferences || {}),
            available: body.available,
            maxConcurrentTasks: body.maxConcurrentTasks || worker.preferences?.maxConcurrentTasks || 5,
        };

        const updated = await this.workerRepo.update(worker.id, {
            preferences: updatedPreferences,
        });

        return {
            success: true,
            availability: {
                available: updatedPreferences.available,
                maxConcurrentTasks: updatedPreferences.maxConcurrentTasks,
            },
            message: 'Worker availability preferences updated',
        };
    }
}
