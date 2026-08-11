import { Controller, Get, Post, Param, Body, NotFoundException } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { ReviewEngineService } from '../../../../review-engine/review.service';
import { SubmissionRepository } from '../../../../shared/database/repositories/submission.repository';
import { Roles } from '../../../../shared/auth/decorators/roles.decorator';
import { CurrentUser } from '../../../../shared/auth/decorators/current-user.decorator';
import { UserRole, User } from '../../../../shared/database/entities/user.entity';

@ApiTags('Admin - Review Queue')
@Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
@ApiBearerAuth('bearer')
@Controller('admin/reviews')
export class AdminReviewController {
    constructor(
        private readonly reviewEngine: ReviewEngineService,
        private readonly submissionRepo: SubmissionRepository,
    ) { }

    @Get()
    @ApiOperation({ summary: 'List all review queue submissions' })
    async getAllReviews() {
        const submissions = await this.submissionRepo.findPendingReviews();
        return {
            success: true,
            submissions,
            total: submissions.length,
        };
    }

    @Get('pending')
    @ApiOperation({ summary: 'List pending review queue' })
    async getPendingReviews() {
        const submissions = await this.submissionRepo.findPendingReviews();
        return {
            success: true,
            submissions,
            count: submissions.length,
        };
    }

    @Get(':submissionId')
    @ApiOperation({ summary: 'Get submission review details' })
    async getReviewById(@Param('submissionId') submissionId: string) {
        const submission = await this.submissionRepo.findById(submissionId);
        if (!submission) {
            throw new NotFoundException('Submission not found');
        }
        return { success: true, submission };
    }

    @Post(':submissionId/approve')
    @ApiOperation({ summary: 'Admin override approve submission' })
    async approveSubmission(
        @Param('submissionId') submissionId: string,
        @Body() data: any,
        @CurrentUser() user: User,
    ) {
        const review = await this.reviewEngine.reviewSubmission(submissionId, {
            action: 'approved',
            reviewedBy: user ? user.id : 'admin',
            notes: data.notes || 'Approved by Admin override',
        });

        return {
            success: true,
            review,
            message: 'Submission approved by admin',
        };
    }

    @Post(':submissionId/reject')
    @ApiOperation({ summary: 'Admin override reject submission' })
    async rejectSubmission(
        @Param('submissionId') submissionId: string,
        @Body() data: any,
        @CurrentUser() user: User,
    ) {
        const review = await this.reviewEngine.reviewSubmission(submissionId, {
            action: 'rejected',
            reviewedBy: user ? user.id : 'admin',
            notes: data.notes || 'Rejected by Admin override',
        });

        return {
            success: true,
            review,
            message: 'Submission rejected by admin',
        };
    }

    @Post(':submissionId/request-changes')
    @ApiOperation({ summary: 'Admin request worker resubmission' })
    async requestChanges(
        @Param('submissionId') submissionId: string,
        @Body() data: any,
        @CurrentUser() user: User,
    ) {
        const review = await this.reviewEngine.reviewSubmission(submissionId, {
            action: 'rejected',
            reviewedBy: user ? user.id : 'admin',
            notes: `[CHANGES_REQUESTED] ${data.notes || 'Admin requested resubmission'}`,
        });

        return {
            success: true,
            review,
            message: 'Resubmission requested from worker by admin',
        };
    }
}
