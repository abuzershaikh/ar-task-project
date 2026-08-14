import {
    Controller,
    Get,
    Post,
    Param,
    Body,
    Query,
    NotFoundException,
    ForbiddenException,
    BadRequestException,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { TaskEngineService } from '../../../../task-engine/task-engine.service';
import { ProgressEngineService } from '../../../../progress-engine/progress.service';
import { SubmissionRepository } from '../../../../shared/database/repositories/submission.repository';
import { ReviewEngineService } from '../../../../review-engine/review.service';
import { CurrentUser } from '../../../../shared/auth/decorators/current-user.decorator';
import { Roles } from '../../../../shared/auth/decorators/roles.decorator';
import { UserRole, User } from '../../../../shared/database/entities/user.entity';

@ApiTags('Worker - Tasks')
@Roles(UserRole.WORKER)
@ApiBearerAuth('bearer')
@Controller('worker/tasks')
export class WorkerTaskController {
    constructor(
        private readonly taskEngine: TaskEngineService,
        private readonly progressEngine: ProgressEngineService,
        private readonly submissionRepo: SubmissionRepository,
        private readonly reviewEngine: ReviewEngineService,
    ) { }

    @Get()
    @ApiOperation({ summary: 'Get worker tasks with optional status filter' })
    @ApiQuery({ name: 'status', required: false })
    async getTasks(@CurrentUser() user: User, @Query('status') status?: string) {
        if (status === 'available') {
            const tasks = await this.taskEngine.getAvailableTasks(user.id);
            return { success: true, tasks };
        }

        const tasks = await this.taskEngine.getWorkerTasks(user.id, status);
        return { success: true, tasks };
    }

    @Get('available')
    @ApiOperation({ summary: 'Get available tasks for worker' })
    async getAvailableTasks(@CurrentUser() user: User) {
        const tasks = await this.taskEngine.getAvailableTasks(user.id);
        return {
            success: true,
            tasks,
            message: 'Available tasks fetched',
        };
    }

    @Get('assigned')
    @ApiOperation({ summary: 'Get tasks assigned to worker' })
    async getAssignedTasks(@CurrentUser() user: User) {
        const tasks = await this.taskEngine.getWorkerTasks(user.id, 'assigned');
        return {
            success: true,
            tasks,
            message: 'Assigned tasks fetched',
        };
    }

    @Get('submitted')
    @ApiOperation({ summary: 'Get worker submitted tasks' })
    async getSubmittedTasks(@CurrentUser() user: User) {
        const tasks = await this.taskEngine.getWorkerTasks(user.id, 'submitted');
        return { success: true, tasks };
    }

    @Get('under-review')
    @ApiOperation({ summary: 'Get worker tasks currently under review' })
    async getUnderReviewTasks(@CurrentUser() user: User) {
        const tasks = await this.taskEngine.getWorkerTasks(user.id, 'under_review');
        return { success: true, tasks };
    }

    @Get('approved')
    @ApiOperation({ summary: 'Get worker approved tasks' })
    async getApprovedTasks(@CurrentUser() user: User) {
        const tasks = await this.taskEngine.getWorkerTasks(user.id, 'approved');
        return { success: true, tasks };
    }

    @Get('rejected')
    @ApiOperation({ summary: 'Get worker rejected tasks' })
    async getRejectedTasks(@CurrentUser() user: User) {
        const tasks = await this.taskEngine.getWorkerTasks(user.id, 'rejected');
        return { success: true, tasks };
    }

    @Get('completed')
    @ApiOperation({ summary: 'Get worker completed tasks' })
    async getCompletedTasks(@CurrentUser() user: User) {
        const tasks = await this.taskEngine.getWorkerTasks(user.id, 'completed');
        return { success: true, tasks };
    }

    @Get('progress')
    @ApiOperation({ summary: 'Get worker task progress summary' })
    async getProgress(@CurrentUser() user: User) {
        const progress = await this.progressEngine.getWorkerProgress(user.id);
        return {
            success: true,
            progress,
        };
    }

    @Get(':id')
    @ApiOperation({ summary: 'Get worker task details with ownership check' })
    async getTaskDetails(@Param('id') taskId: string, @CurrentUser() user: User) {
        const task = await this.taskEngine.getTaskById(taskId);
        if (!task) {
            throw new NotFoundException('Task not found');
        }

        if (task.assignedTo && task.assignedTo !== user.id) {
            throw new ForbiddenException('You do not have permission to view this task');
        }

        return {
            success: true,
            task,
        };
    }

    @Get(':id/timeline')
    @ApiOperation({ summary: 'Get task state transitions timeline' })
    async getTaskTimeline(@Param('id') taskId: string, @CurrentUser() user: User) {
        const task = await this.taskEngine.getTaskById(taskId);
        if (!task || (task.assignedTo && task.assignedTo !== user.id)) {
            throw new NotFoundException('Task not found');
        }

        return {
            success: true,
            taskId,
            timeline: [
                { status: 'CREATED', timestamp: task.createdAt },
                { status: task.status, timestamp: task.updatedAt },
            ],
        };
    }

    @Get(':id/submission')
    @ApiOperation({ summary: 'Get worker submission proof data for task' })
    async getTaskSubmission(@Param('id') taskId: string, @CurrentUser() user: User) {
        const submission = await this.submissionRepo.findByTaskId(taskId);
        if (!submission || submission.workerId !== user.id) {
            throw new NotFoundException('Submission not found for task');
        }

        return {
            success: true,
            submission,
        };
    }

    @Get(':id/proof')
    @ApiOperation({ summary: 'Get uploaded proof files for task' })
    async getTaskProof(@Param('id') taskId: string, @CurrentUser() user: User) {
        const submission = await this.submissionRepo.findByTaskId(taskId);
        if (!submission || submission.workerId !== user.id) {
            throw new NotFoundException('Proof not found');
        }

        return {
            success: true,
            proofs: submission.proofs || [],
        };
    }

    @Get(':id/rejection')
    @ApiOperation({ summary: 'Get rejection reason and details for rejected task' })
    async getTaskRejection(@Param('id') taskId: string, @CurrentUser() user: User) {
        const submission = await this.submissionRepo.findByTaskId(taskId);
        if (!submission || submission.workerId !== user.id) {
            throw new NotFoundException('Task submission not found');
        }

        return {
            success: true,
            taskId,
            status: submission.status,
            reasonCode: submission.reviewNotes || 'PROOF_REJECTED',
            rejectionReason: submission.reviewNotes || 'Task submission rejected by reviewer',
            rejectedAt: submission.reviewedAt,
            resubmissionAllowed: submission.status === 'rejected',
        };
    }

    @Post(':id/accept')
    @ApiOperation({ summary: 'Accept an assigned task' })
    async acceptTask(@Param('id') taskId: string, @CurrentUser() user: User) {
        await this.taskEngine.acceptTask({ taskId, workerId: user.id });
        return {
            success: true,
            message: 'Task accepted successfully',
        };
    }

    @Post(':id/start')
    @ApiOperation({ summary: 'Start work on accepted task' })
    async startTask(@Param('id') taskId: string, @CurrentUser() user: User) {
        await this.taskEngine.startTask({ taskId, workerId: user.id });
        return {
            success: true,
            message: 'Task started',
        };
    }

    @Post(':id/submit')
    @ApiOperation({ summary: 'Submit completed task with proof data' })
    async submitTask(
        @Param('id') taskId: string,
        @Body() body: { data?: any; proofs?: any[] },
        @CurrentUser() user: User,
    ) {
        // 1. Mark task as submitted in task engine
        await this.taskEngine.submitTask({
            taskId,
            workerId: user.id,
            data: {
                ...(body.data || body),
                proofs: body.proofs || [],
            },
        });

        // 2. Create the missing TaskSubmission record
        let submission = await this.submissionRepo.findByTaskId(taskId);
        if (!submission) {
            submission = await this.submissionRepo.create({
                taskId,
                workerId: user.id,
                data: body.data || body || {},
                proofs: body.proofs || [],
                status: 'submitted',
                reviewStatus: 'pending'
            });
        }

        // 3. Delegate to Review Engine to assign the reviewer (Buyer, Admin, or System)
        await this.reviewEngine.assignReviewer(submission.id);

        return {
            success: true,
            message: 'Task submitted for review',
        };
    }

    @Post(':id/resubmit')
    @ApiOperation({ summary: 'Resubmit task after addressing buyer/admin feedback' })
    async resubmitTask(
        @Param('id') taskId: string,
        @Body() body: { data?: any; proofs?: any[]; resubmissionNotes?: string },
        @CurrentUser() user: User,
    ) {
        let submission = await this.submissionRepo.findByTaskId(taskId);
        if (!submission || submission.workerId !== user.id) {
            throw new NotFoundException('Previous submission not found');
        }

        await this.taskEngine.submitTask({
            taskId,
            workerId: user.id,
            data: {
                ...(body.data || body),
                proofs: body.proofs || submission.proofs,
                resubmissionNotes: body.resubmissionNotes,
                isResubmission: true,
            },
        });

        // Update submission record
        await this.submissionRepo.update(submission.id, {
            data: body.data || body || {},
            proofs: body.proofs || submission.proofs,
            status: 'submitted',
            reviewStatus: 'pending'
        });

        // Re-assign for review
        await this.reviewEngine.assignReviewer(submission.id);

        return {
            success: true,
            message: 'Task resubmitted successfully for review',
        };
    }
}
