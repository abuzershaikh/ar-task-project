import {
    Controller,
    Get,
    Post,
    Param,
    Body,
    Query,
    NotFoundException,
    ForbiddenException,
    HttpCode,
    HttpStatus,
    HttpException,
    Logger,
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
    private readonly logger = new Logger(BuyerReviewController.name);

    constructor(
        private readonly reviewEngine: ReviewEngineService,
        private readonly submissionRepo: SubmissionRepository,
        private readonly orderRepo: OrderRepository,
        private readonly taskRepo: TaskRepository,
        private readonly userRepo: UserRepository,
    ) { }

    /**
     * Check if user owns the order, or is SUPER_ADMIN/ADMIN (who can access all orders)
     */
    private async isOwnerOrAdmin(user: User, order: any): Promise<boolean> {
        if (!order) return false;
        if (user.role === UserRole.SUPER_ADMIN || user.role === UserRole.ADMIN) return true;
        return order.buyerId === user.id;
    }

    /**
     * Get orders belonging to this user (or ALL orders if user is admin)
     */
    private async getBuyerOrders(user: User): Promise<any[]> {
        if (user.role === UserRole.SUPER_ADMIN || user.role === UserRole.ADMIN) {
            return this.orderRepo.findAll();
        }
        return this.orderRepo.findByBuyer(user.id);
    }

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
            proofUrl = sub.proofs[0]?.url || sub.proofs[0]?.path || sub.proofs[0]?.filePath || '';
        }
        if (!proofUrl && sub.data) {
            proofUrl = sub.data.proofUrl || sub.data.screenshotUrl || sub.data.image || sub.data.fileUrl || '';
        }

        const appUrl = process.env.APP_URL || 'http://65.20.77.112:3000';
        if (proofUrl && !proofUrl.startsWith('http')) {
            const cleanKey = proofUrl.replace(/^\/+/, '').replace(/^uploads\//, '');
            proofUrl = `${appUrl}/api/v1/files/raw/${cleanKey}`;
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

    // ──────────────────────────────────────────────────────────
    // STATIC routes MUST come BEFORE :submissionId param routes
    // Otherwise NestJS matches 'auto-approve-status' as :submissionId → 404
    // ──────────────────────────────────────────────────────────

    @Get('pending')
    @ApiOperation({ summary: 'Get pending submission review queue for buyer' })
    async getPendingReviews(@CurrentUser() user: User) {
        const buyerOrders = await this.getBuyerOrders(user);
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

    @Get('auto-approve-status')
    @ApiOperation({ summary: 'Get current auto-approve setting' })
    async getAutoApproveStatus(
        @Query('orderId') orderId: string | undefined,
        @CurrentUser() user: User,
    ) {
        if (orderId) {
            const order = await this.orderRepo.findById(orderId);
            if (!order || !(await this.isOwnerOrAdmin(user, order))) {
                throw new NotFoundException('Order not found or unauthorized');
            }
            const mode = (order.reviewMode || '').toLowerCase();
            const isAuto = mode === 'automatic' || mode === 'auto' || mode === 'system' || order.requirements?.autoApprove === true;
            return {
                success: true,
                orderId,
                autoApprove: isAuto,
            };
        }

        // Global buyer check across active orders
        const buyerOrders = await this.getBuyerOrders(user);
        const activeOrders = buyerOrders.filter(o => o.status === 'active' || o.status === 'ACTIVE');
        const targetList = activeOrders.length > 0 ? activeOrders : buyerOrders;

        const autoCount = targetList.filter(o => {
            const mode = (o.reviewMode || '').toLowerCase();
            return mode === 'automatic' || mode === 'auto' || mode === 'system' || o.requirements?.autoApprove === true;
        }).length;

        const isAutoApprove = targetList.length > 0 && autoCount === targetList.length;

        return {
            success: true,
            autoApprove: isAutoApprove || (targetList.length > 0 && autoCount > 0),
            autoCount,
            totalOrders: targetList.length,
        };
    }

    @Post('approve-all')
    @HttpCode(HttpStatus.OK)
    @ApiOperation({ summary: 'Approve all pending submissions in bulk' })
    async approveAll(
        @Body() body: { orderId?: string; submissionIds?: string[]; notes?: string },
        @CurrentUser() user: User,
    ) {
        // Fetch all orders of this buyer to enforce ownership
        const buyerOrders = await this.getBuyerOrders(user);
        const buyerOrderIds = new Set(buyerOrders.map((o) => o.id));

        // If specific orderId requested, verify ownership
        if (body?.orderId && !buyerOrderIds.has(body.orderId)) {
            throw new ForbiddenException('You do not own this order');
        }

        const targetOrderIds = body?.orderId ? [body.orderId] : Array.from(buyerOrderIds);

        // Fetch pending reviews
        const pendingSubmissions = await this.submissionRepo.findPendingReviews();
        const submissionsToApprove: TaskSubmission[] = [];

        for (const sub of pendingSubmissions) {
            // If explicit submissionIds were provided, filter by them
            if (body?.submissionIds && body.submissionIds.length > 0) {
                if (!body.submissionIds.includes(sub.id) && !body.submissionIds.includes(sub.taskId)) {
                    continue;
                }
            }

            const task = await this.taskRepo.findById(sub.taskId);
            if (task && targetOrderIds.includes(task.orderId)) {
                submissionsToApprove.push(sub);
            }
        }

        // Edge case: nothing found to approve
        if (submissionsToApprove.length === 0) {
            return {
                success: true,
                totalRequested: 0,
                approvedCount: 0,
                failedCount: 0,
                message: 'No pending submissions found to approve',
            };
        }

        const approvedResults: any[] = [];
        const errors: any[] = [];

        for (const sub of submissionsToApprove) {
            try {
                const review = await this.reviewEngine.reviewSubmission(sub.id, {
                    action: 'approved',
                    reviewedBy: user.id,
                    notes: body?.notes || 'Bulk approved by buyer',
                });
                approvedResults.push({ submissionId: sub.id, action: review?.action || 'approved' });
            } catch (err: any) {
                this.logger.error(`Bulk approve error for submission ${sub.id}: ${err.message}`, err.stack);
                errors.push({ submissionId: sub.id, error: err.message });
            }
        }

        // Determine success based on actual results
        const allFailed = approvedResults.length === 0 && errors.length > 0;
        const partialFailure = approvedResults.length > 0 && errors.length > 0;

        let message: string;
        if (allFailed) {
            message = `All ${errors.length} submissions failed to approve. Check errors for details.`;
        } else if (partialFailure) {
            message = `Approved ${approvedResults.length} submissions, but ${errors.length} failed. Check errors for details.`;
        } else {
            message = `Successfully approved ${approvedResults.length} submissions`;
        }

        // If ALL failed, return HTTP 207 Multi-Status so the client knows it wasn't a clean success
        if (allFailed) {
            throw new HttpException(
                {
                    success: false,
                    totalRequested: submissionsToApprove.length,
                    approvedCount: 0,
                    failedCount: errors.length,
                    errors,
                    message,
                },
                HttpStatus.UNPROCESSABLE_ENTITY,
            );
        }

        return {
            success: !allFailed,
            totalRequested: submissionsToApprove.length,
            approvedCount: approvedResults.length,
            failedCount: errors.length,
            errors: errors.length > 0 ? errors : undefined,
            message,
        };
    }

    @Post('auto-approve-toggle')
    @ApiOperation({ summary: 'Toggle auto-approval setting on or off' })
    async toggleAutoApprove(
        @Body() body: { autoApprove: boolean; orderId?: string },
        @CurrentUser() user: User,
    ) {
        const { autoApprove, orderId } = body;

        let affectedOrders: any[] = [];
        if (orderId) {
            const order = await this.orderRepo.findById(orderId);
            if (!order || !(await this.isOwnerOrAdmin(user, order))) {
                throw new NotFoundException('Order not found or unauthorized');
            }
            affectedOrders = [order];
        } else {
            const buyerOrders = await this.getBuyerOrders(user);
            const activeOrders = buyerOrders.filter(o => o.status === 'active' || o.status === 'ACTIVE');
            affectedOrders = activeOrders.length > 0 ? activeOrders : buyerOrders;
        }

        for (const order of affectedOrders) {
            order.reviewMode = autoApprove ? 'automatic' : 'buyer';
            order.requirements = {
                ...(order.requirements || {}),
                autoApprove: autoApprove,
            };
            await this.orderRepo.save(order);
        }

        // If turning ON, automatically approve existing pending submissions for these orders!
        let autoApprovedCount = 0;
        const autoApproveErrors: any[] = [];
        if (autoApprove && affectedOrders.length > 0) {
            const affectedOrderIds = new Set(affectedOrders.map(o => o.id));
            const pendingSubmissions = await this.submissionRepo.findPendingReviews();
            for (const sub of pendingSubmissions) {
                const task = await this.taskRepo.findById(sub.taskId);
                if (task && affectedOrderIds.has(task.orderId)) {
                    try {
                        await this.reviewEngine.reviewSubmission(sub.id, {
                            action: 'approved',
                            reviewedBy: 'system',
                            notes: 'Auto-approved upon enabling auto-approval toggle',
                        });
                        autoApprovedCount++;
                    } catch (e: any) {
                        this.logger.error(`Error auto-approving pending submission ${sub.id}: ${e.message}`, e.stack);
                        autoApproveErrors.push({ submissionId: sub.id, error: e.message });
                    }
                }
            }
        }

        return {
            success: true,
            autoApprove,
            affectedOrdersCount: affectedOrders.length,
            existingApprovedCount: autoApprovedCount,
            failedCount: autoApproveErrors.length,
            errors: autoApproveErrors.length > 0 ? autoApproveErrors : undefined,
            message: `Auto-approval has been ${autoApprove ? 'enabled' : 'disabled'}${autoApprovedCount > 0 ? ` and ${autoApprovedCount} pending submissions were approved` : ''}${autoApproveErrors.length > 0 ? ` (${autoApproveErrors.length} failed)` : ''}`,
        };
    }

    // ──────────────────────────────────────────────────────────
    // PARAM routes AFTER all static routes
    // ──────────────────────────────────────────────────────────

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

        try {
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
        } catch (err: any) {
            this.logger.error(`Approve error for submission ${submission.id}: ${err.message}`, err.stack);
            throw new HttpException(
                {
                    success: false,
                    message: `Approval failed: ${err.message}`,
                    error: err.message,
                },
                HttpStatus.UNPROCESSABLE_ENTITY,
            );
        }
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
