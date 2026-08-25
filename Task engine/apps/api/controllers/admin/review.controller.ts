import { Controller, Get, Post, Param, Body, NotFoundException } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { ReviewEngineService } from '../../../../review-engine/review.service';
import { SubmissionRepository } from '../../../../shared/database/repositories/submission.repository';
import { TaskRepository } from '../../../../shared/database/repositories/task.repository';
import { UserRepository } from '../../../../shared/database/repositories/user.repository';
import { OrderRepository } from '../../../../shared/database/repositories/order.repository';
import { Roles } from '../../../../shared/auth/decorators/roles.decorator';
import { CurrentUser } from '../../../../shared/auth/decorators/current-user.decorator';
import { UserRole, User } from '../../../../shared/database/entities/user.entity';
import { TaskSubmission } from '../../../../shared/database/entities/submission.entity';

@ApiTags('Admin - Review Queue')
@Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
@ApiBearerAuth('bearer')
@Controller('admin/reviews')
export class AdminReviewController {
    constructor(
        private readonly reviewEngine: ReviewEngineService,
        private readonly submissionRepo: SubmissionRepository,
        private readonly taskRepo: TaskRepository,
        private readonly userRepo: UserRepository,
        private readonly orderRepo: OrderRepository,
    ) { }

    private async formatSubmission(sub: TaskSubmission) {
        let taskTitle = 'Task Execution';
        let orderId = '';
        let workerName = 'Worker';
        let workerEmail = '';

        if (sub.taskId) {
            try {
                const task = await this.taskRepo.findById(sub.taskId);
                if (task) {
                    taskTitle = task.taskType || 'Task Execution';
                    orderId = task.orderId || '';
                }
            } catch (_) {}
        }

        if (sub.workerId) {
            try {
                const worker = await this.userRepo.findById(sub.workerId);
                if (worker) {
                    workerName = worker.fullName || (worker as any).name || 'Worker';
                    workerEmail = worker.email || '';
                }
            } catch (_) {}
        }

        let proofUrl = '';
        if (Array.isArray(sub.proofs) && sub.proofs.length > 0) {
            proofUrl = sub.proofs[0]?.url || sub.proofs[0]?.path || '';
        }
        if (!proofUrl && sub.data) {
            proofUrl = sub.data.proofUrl || sub.data.screenshotUrl || '';
        }

        let proofText = '';
        if (sub.data) {
            proofText = sub.data.textProof || sub.data.proofText || sub.data.notes || '';
        }

        return {
            ...sub,
            taskTitle,
            orderId,
            workerName,
            workerEmail,
            proofUrl,
            proofScreenshotUrl: proofUrl,
            proofText,
        };
    }

    @Get()
    @ApiOperation({ summary: 'List all review queue submissions' })
    async getAllReviews() {
        const submissions = await this.submissionRepo.findPendingReviews();
        const formatted = await Promise.all(submissions.map((sub) => this.formatSubmission(sub)));
        return {
            success: true,
            submissions: formatted,
            total: formatted.length,
        };
    }

    @Get('pending')
    @ApiOperation({ summary: 'List pending review queue' })
    async getPendingReviews() {
        const submissions = await this.submissionRepo.findPendingReviews();
        const formatted = await Promise.all(submissions.map((sub) => this.formatSubmission(sub)));
        return {
            success: true,
            submissions: formatted,
            count: formatted.length,
        };
    }

    @Get(':submissionId')
    @ApiOperation({ summary: 'Get submission review details' })
    async getReviewById(@Param('submissionId') submissionId: string) {
        let submission = await this.submissionRepo.findById(submissionId);
        if (!submission) {
            submission = await this.submissionRepo.findByTaskId(submissionId);
        }
        if (!submission) {
            throw new NotFoundException('Submission not found');
        }
        const formatted = await this.formatSubmission(submission);
        return { success: true, submission: formatted };
    }

    @Post(':submissionId/approve')
    @ApiOperation({ summary: 'Admin override approve submission' })
    async approveSubmission(
        @Param('submissionId') submissionId: string,
        @Body() data: any,
        @CurrentUser() user: User,
    ) {
        let submission = await this.submissionRepo.findById(submissionId);
        if (!submission) {
            submission = await this.submissionRepo.findByTaskId(submissionId);
        }
        if (!submission) {
            throw new NotFoundException('Submission not found');
        }

        const review = await this.reviewEngine.reviewSubmission(submission.id, {
            action: 'approved',
            reviewedBy: user ? user.id : 'admin',
            notes: data?.notes || 'Approved by Admin override',
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
        let submission = await this.submissionRepo.findById(submissionId);
        if (!submission) {
            submission = await this.submissionRepo.findByTaskId(submissionId);
        }
        if (!submission) {
            throw new NotFoundException('Submission not found');
        }

        const review = await this.reviewEngine.reviewSubmission(submission.id, {
            action: 'rejected',
            reviewedBy: user ? user.id : 'admin',
            notes: data?.notes || 'Rejected by Admin override',
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
        let submission = await this.submissionRepo.findById(submissionId);
        if (!submission) {
            submission = await this.submissionRepo.findByTaskId(submissionId);
        }
        if (!submission) {
            throw new NotFoundException('Submission not found');
        }

        const review = await this.reviewEngine.reviewSubmission(submission.id, {
            action: 'rejected',
            reviewedBy: user ? user.id : 'admin',
            notes: `[CHANGES_REQUESTED] ${data?.notes || 'Admin requested resubmission'}`,
        });

        return {
            success: true,
            review,
            message: 'Resubmission requested from worker by admin',
        };
    }
}
