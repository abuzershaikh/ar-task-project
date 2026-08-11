import {
    Controller,
    Post,
    Param,
    Body,
    BadRequestException,
    NotFoundException,
    ForbiddenException,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { TaskRepository } from '../../../../shared/database/repositories/task.repository';
import { OrderRepository } from '../../../../shared/database/repositories/order.repository';
import { RatingEngineService } from '../../../../shared/services/rating-engine.service';
import { Roles } from '../../../../shared/auth/decorators/roles.decorator';
import { CurrentUser } from '../../../../shared/auth/decorators/current-user.decorator';
import { UserRole, User } from '../../../../shared/database/entities/user.entity';

@ApiTags('Buyer - Ratings')
@Roles(UserRole.BUYER)
@ApiBearerAuth('bearer')
@Controller('buyer/tasks')
export class BuyerRatingController {
    constructor(
        private readonly taskRepo: TaskRepository,
        private readonly orderRepo: OrderRepository,
        private readonly ratingEngine: RatingEngineService,
    ) { }

    @Post(':taskId/rating')
    @ApiOperation({ summary: 'Rate worker performance on completed task (feeds into Matching Brain)' })
    async rateTask(
        @Param('taskId') taskId: string,
        @Body() body: { rating: number; score?: number; feedback?: string },
        @CurrentUser() user: User,
    ) {
        const ratingVal = body.rating || body.score;
        if (!ratingVal || ratingVal < 1 || ratingVal > 5) {
            throw new BadRequestException('Rating score must be between 1 and 5');
        }

        const task = await this.taskRepo.findById(taskId);
        if (!task || !task.assignedTo) {
            throw new NotFoundException('Task or worker not found');
        }

        const order = await this.orderRepo.findById(task.orderId);
        if (!order || order.buyerId !== user.id) {
            throw new ForbiddenException('You do not have access to rate this task');
        }

        const result = await this.ratingEngine.submitTaskRating({
            buyerId: user.id,
            taskId,
            score: ratingVal,
            feedback: body.feedback,
        });

        return {
            success: true,
            result,
            message: 'Worker rated successfully and Matching Brain updated',
        };
    }
}
