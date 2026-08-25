import {
    Controller,
    Get,
    Post,
    Param,
    Body,
    NotFoundException,
    ForbiddenException,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { ReviewEngineService } from '../../../../review-engine/review.service';
import { SubmissionRepository } from '../../../../shared/database/repositories/submission.repository';
import { OrderRepository } from '../../../../shared/database/repositories/order.repository';
import { TaskRepository } from '../../../../shared/database/repositories/task.repository';
import { UserRepository } from '../../../../shared/database/repositories/user.repository';
import { Roles } from '../../../../shared/auth/decorators/roles.decorator';
import { CurrentUser } from '../../../../shared/auth/decorators/current-user.decorator';
import { UserRole, User } from '../../../../shared/database/entities/user.entity';
import { TaskSubmission } from '../../../../shared/database/entities/submission.entity';

@ApiTags('Buyer - Reviews')
@Roles(UserRole.BUYER)
@ApiBearerAuth('bearer')
@Controller('buyer/reviews')
export class BuyerReviewController {
    constructor(
        private readonly reviewEngine: ReviewEngineService,
        private readonly submissionRepo: SubmissionRepository,
        private readonly orderRepo: OrderRepository,
        private readonly taskRepo: TaskRepository,
        private readonly userRepo: UserRepository,
    ) { }

    private async formatSubmission(sub: TaskSubmission, task?: any) {
        let taskTitle = task?.taskType || 'Task Execution';
        let orderId = task?.orderId || '';
        let workerName = 'Worker';
        let workerEmail = '';

        if (!task && sub.taskId) {
            try {
                task = await this.taskRepo.findById(sub.taskId);
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
            rewardAmount: task?.rewardAmount || 0,
        };
    }

    @Get('pending')
    @ApiOperation({ summary: 'Get pending submission review queue for buyer' })
    async getPendingReviews(@CurrentUser() user: User) {
        const buyerOrders = await this.orderRepo.findByBuyer(user.id);
        const orderIds = buyerOrders.map((o) => o.id);

        const pendingSubmissions = await this.submissionRepo.findPendingReviews();
        const buyerPendingSubmissions: any[] = [];

        for (const sub of pendingSubmissions) {
            const task = await this.taskRepo.findById(sub.taskId);
            if (task && (orderIds.length === 0 || orderIds.includes(task.orderId))) {
                const formatted = await this.formatSubmission(sub, task);
                buyerPendingSubmissions.push(formatted);
            }
        }

        return {
            success: true,
            submissions: buyerPendingSubmissions,
            count: buyerPendingSubmissions.length,
        };
    }

    @Get(':submissionId')
    @ApiOperation({ summary: 'Get submission review details' })
    async getReviewDetail(
        @Param('submissionId') submissionId: string,
        @CurrentUser() user: User,
    ) {
        let submission = await this.submissionRepo.findById(submissionId);
        if (!submission) {
            submission = await this.submissionRepo.findByTaskId(submissionId);
        }
        if (!submission) {
            throw new NotFoundException('Submission not found');
        }

        const task = await this.taskRepo.findById(submission.taskId);
        let order: any = null;
        if (task && task.orderId) {
            order = await this.orderRepo.findById(task.orderId);
        }

        const formatted = await this.formatSubmission(submission, task);

        return {
            success: true,
            submission: formatted,
            task,
            order,
        };
    }

    @Post(':submissionId/approve')
    @ApiOperation({ summary: 'Approve submission' })
    async approveSubmission(
        @Param('submissionId') submissionId: string,
        @Body() body: { notes?: string },
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
            reviewedBy: user.id,
            notes: body?.notes || 'Approved by buyer',
        });

        return {
            success: true,
            review,
            message: 'Submission approved successfully',
        };
    }

    @Post(':submissionId/reject')
    @ApiOperation({ summary: 'Reject submission with mandatory structured reason' })
    async rejectSubmission(
        @Param('submissionId') submissionId: string,
        @Body() body: { reasonCode?: string; note?: string; notes?: string },
        @CurrentUser() user: User,
    ) {
        let submission = await this.submissionRepo.findById(submissionId);
        if (!submission) {
            submission = await this.submissionRepo.findByTaskId(submissionId);
        }
        if (!submission) {
            throw new NotFoundException('Submission not found');
        }

        const reasonCode = body.reasonCode || 'INVALID_PROOF';
        const noteText = body.note || body.notes || 'Submission rejected by buyer';

        const review = await this.reviewEngine.reviewSubmission(submission.id, {
            action: 'rejected',
            reviewedBy: user.id,
            notes: `[${reasonCode}] ${noteText}`,
        });

        return {
            success: true,
            review,
            reasonCode,
            message: 'Submission rejected',
        };
    }

    @Post(':submissionId/request-changes')
    @ApiOperation({ summary: 'Request changes/resubmission from worker' })
    async requestChanges(
        @Param('submissionId') submissionId: string,
        @Body() body: { reasonCode?: string; note: string },
        @CurrentUser() user: User,
    ) {
        let submission = await this.submissionRepo.findById(submissionId);
        if (!submission) {
            submission = await this.submissionRepo.findByTaskId(submissionId);
        }
        if (!submission) {
            throw new NotFoundException('Submission not found');
        }

        const reasonCode = body.reasonCode || 'CHANGES_REQUESTED';
        const review = await this.reviewEngine.reviewSubmission(submission.id, {
            action: 'changes_requested',
            reviewedBy: user.id,
            notes: `[${reasonCode}] Changes requested: ${body.note}`,
        });

        return {
            success: true,
            review,
            reasonCode,
            message: 'Changes requested from worker. Resubmission unlocked.',
        };
    }
}
