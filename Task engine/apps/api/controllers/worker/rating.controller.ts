import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { RatingRepository } from '../../../../shared/database/repositories/rating.repository';
import { WorkerRepository } from '../../../../shared/database/repositories/worker.repository';
import { Roles } from '../../../../shared/auth/decorators/roles.decorator';
import { CurrentUser } from '../../../../shared/auth/decorators/current-user.decorator';
import { UserRole, User } from '../../../../shared/database/entities/user.entity';

@ApiTags('Worker - Ratings')
@Roles(UserRole.WORKER)
@ApiBearerAuth('bearer')
@Controller('worker/ratings')
export class WorkerRatingController {
    constructor(
        private readonly ratingRepo: RatingRepository,
        private readonly workerRepo: WorkerRepository,
    ) { }

    @Get()
    @ApiOperation({ summary: 'Get ratings received by worker' })
    async getRatings(@CurrentUser() user: User) {
        const worker = await this.workerRepo.findByUserId(user.id);
        if (!worker) {
            return { success: true, ratings: [] };
        }

        const ratings = await this.ratingRepo.findByWorkerId(worker.id);
        return {
            success: true,
            ratings,
        };
    }

    @Get('summary')
    @ApiOperation({ summary: 'Get worker rating summary' })
    async getSummary(@CurrentUser() user: User) {
        const worker = await this.workerRepo.findByUserId(user.id);
        if (!worker) {
            return {
                success: true,
                summary: { average: 0, count: 0 },
            };
        }

        const summary = await this.ratingRepo.getWorkerRatingSummary(worker.id);
        return {
            success: true,
            summary,
        };
    }
}
