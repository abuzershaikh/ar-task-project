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
import { ExecutionEngineService } from '../../../../execution-engine/execution.service';
import { ReviewEngineService } from '../../../../review-engine/review.service';
import { CurrentUser } from '../../../../shared/auth/decorators/current-user.decorator';
import { Roles } from '../../../../shared/auth/decorators/roles.decorator';
import { UserRole, User } from '../../../../shared/database/entities/user.entity';
import { WorkerRepository } from '../../../../shared/database/repositories/worker.repository';
import { OrderRepository } from '../../../../shared/database/repositories/order.repository';
import { TaskRepository } from '../../../../shared/database/repositories/task.repository';
import { EarningEngineService } from '../../../../earning-engine/earning.service';
import { EarningRepository } from '../../../../shared/database/repositories/earning.repository';
import { SystemSettingsRepository } from '../../../../shared/database/repositories/system-settings.repository';
import { NotificationEngineService } from '../../../../notification-engine/notification.service';

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
        private readonly executionEngine: ExecutionEngineService,
        private readonly workerRepo: WorkerRepository,
        private readonly orderRepo: OrderRepository,
        private readonly taskRepo: TaskRepository,
        private readonly earningEngine: EarningEngineService,
        private readonly earningRepo: EarningRepository,
        private readonly settingsRepo: SystemSettingsRepository,
        private readonly notificationEngine: NotificationEngineService,
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

    @Get('accepted')
    @ApiOperation({ summary: 'Get tasks accepted/assigned to worker' })
    async getAcceptedTasks(@CurrentUser() user: User) {
        return this.getAssignedTasks(user);
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

    @Get('retention-tracked')
    @ApiOperation({ summary: 'Get worker active app install tasks being tracked for retention' })
    async getRetentionTrackedTasks(@CurrentUser() user: User) {
        const worker = await this.workerRepo.findWorker(user.id);
        const workerId = worker ? worker.id : user.id;

        // Fetch tasks assigned to this worker (checking both user.id and worker.id)
        const userTasks = await this.taskRepo.findByWorker(user.id);
        const workerProfileTasks = worker ? await this.taskRepo.findByWorker(worker.id) : [];

        // Deduplicate by task ID
        const taskMap = new Map<string, any>();
        for (const t of [...userTasks, ...workerProfileTasks]) {
            taskMap.set(t.id, t);
        }

        // Fetch system default retention hours if not configured in task
        const retentionSetting = await this.settingsRepo.findByKey('app_install_min_retention_hours');
        const defaultRetentionHours = retentionSetting ? Number(retentionSetting.value) : 24.0;

        const now = new Date();
        const trackedTasks: any[] = [];

        for (const task of taskMap.values()) {
            const taskType = (task.taskType || '').toUpperCase();
            const req = task.requirements || {};
            const meta = task.metadata || {};

            const isAppInstall =
                taskType.includes('APP_INSTALL') ||
                taskType.includes('PLAY_STORE') ||
                taskType.includes('INSTALL') ||
                req.isAppInstall === true ||
                req.minRetentionHours != null ||
                req.min_retention_hours != null ||
                meta.minRetentionHours != null;

            if (!isAppInstall) continue;

            const status = (task.status || '').toLowerCase();
            if (status !== 'approved' && status !== 'completed' && status !== 'submitted' && status !== 'under_review') {
                continue;
            }

            // Skip if already breached or verified completed
            if (meta.retentionStatus === 'BREACHED' || meta.retentionStatus === 'VERIFIED_COMPLETED') {
                continue;
            }

            const minHours = Number(meta.minRetentionHours || req.minRetentionHours || req.min_retention_hours || defaultRetentionHours);

            let retentionUntil = meta.retentionUntil ? new Date(meta.retentionUntil) : null;
            if (!retentionUntil) {
                const baseTime = task.completedAt || task.submittedAt || task.updatedAt || new Date();
                retentionUntil = new Date(new Date(baseTime).getTime() + minHours * 3600 * 1000);
                task.metadata = {
                    ...meta,
                    minRetentionHours: minHours,
                    retentionUntil: retentionUntil.toISOString(),
                    retentionStatus: 'ACTIVE',
                    installedAt: meta.installedAt || baseTime,
                };
                await this.taskRepo.save(task);
            }

            // If retention window already passed, auto-complete
            if (now.getTime() >= retentionUntil.getTime()) {
                task.metadata = {
                    ...task.metadata,
                    retentionStatus: 'VERIFIED_COMPLETED',
                    verifiedCompletedAt: now.toISOString(),
                };
                await this.taskRepo.save(task);
                continue;
            }

            trackedTasks.push({
                id: task.id,
                taskId: task.id,
                taskType: task.taskType,
                status: task.status,
                requirements: task.requirements,
                metadata: task.metadata,
                targetUrl: req.targetUrl || req.url || req.playStoreUrl || req.link,
                retentionUntil: retentionUntil.toISOString(),
                minRetentionHours: minHours,
                rewardAmount: task.rewardAmount,
            });
        }

        return {
            success: true,
            tasks: trackedTasks,
            count: trackedTasks.length,
        };
    }

    @Post('retention-report')
    @ApiOperation({ summary: 'Process worker retention status reports and penalize early uninstalls' })
    async reportRetentionStatus(
        @Body() body: { reports: Array<{ taskId: string; packageName: string; isInstalled: boolean; checkedAt?: string }> },
        @CurrentUser() user: User,
    ) {
        const reports = body?.reports || [];
        if (!Array.isArray(reports) || reports.length === 0) {
            return { success: true, processedCount: 0, breachedCount: 0, deductionApplied: false };
        }

        const worker = await this.workerRepo.findWorker(user.id);
        const workerId = worker ? worker.id : user.id;

        let breachedCount = 0;
        let deductionApplied = false;
        const now = new Date();

        for (const report of reports) {
            const { taskId, packageName, isInstalled } = report;
            if (!taskId) continue;

            const task = await this.taskRepo.findById(taskId);
            if (!task) continue;

            // Verify worker ownership
            if (task.assignedTo && task.assignedTo !== user.id && task.assignedTo !== workerId) {
                continue;
            }

            const meta = task.metadata || {};

            // If app was UNINSTALLED before retention ended
            if (isInstalled === false) {
                // If already breached, avoid duplicate penalties
                if (meta.retentionStatus === 'BREACHED') continue;

                const retentionUntil = meta.retentionUntil ? new Date(meta.retentionUntil) : null;
                const isStillInWindow = !retentionUntil || now.getTime() < retentionUntil.getTime();

                if (isStillInWindow || meta.retentionStatus === 'ACTIVE') {
                    // Mark task as BREACHED
                    task.status = 'BREACHED';
                    task.metadata = {
                        ...meta,
                        retentionStatus: 'BREACHED',
                        breachedAt: now.toISOString(),
                        uninstalledPackage: packageName,
                        breachReason: `Worker uninstalled package ${packageName} before required retention period`,
                    };
                    await this.taskRepo.save(task);

                    // Find earning to reverse
                    const earning = await this.earningRepo.findByTaskId(task.id);
                    if (earning && earning.status !== 'reversed') {
                        // Reverse earning: Atomic debit from wallet (allows negative balance if withdrawn)
                        await this.earningEngine.reverseEarning(earning.id);
                        deductionApplied = true;

                        // Notify worker
                        try {
                            await this.notificationEngine.sendNotification(
                                user.id,
                                `⚠️ Early Uninstall Penalty: You uninstalled ${packageName} before the required retention period. Reward of ₹${earning.amount} was deducted from your wallet balance.`,
                                'RETENTION_BREACH_PENALTY',
                                { taskId: task.id, earningId: earning.id, amount: earning.amount, packageName },
                            );
                        } catch (_) {}
                    }

                    breachedCount++;
                }
            } else if (isInstalled === true) {
                // If app is still installed and time has passed retentionUntil, mark completed
                const retentionUntil = meta.retentionUntil ? new Date(meta.retentionUntil) : null;
                if (retentionUntil && now.getTime() >= retentionUntil.getTime() && meta.retentionStatus === 'ACTIVE') {
                    task.metadata = {
                        ...meta,
                        retentionStatus: 'VERIFIED_COMPLETED',
                        verifiedCompletedAt: now.toISOString(),
                    };
                    await this.taskRepo.save(task);
                }
            }
        }

        return {
            success: true,
            message: 'Retention check reports processed',
            processedCount: reports.length,
            breachedCount,
            deductionApplied,
        };
    }

    @Get(':id')
    @ApiOperation({ summary: 'Get worker task details with ownership check' })
    async getTaskDetails(@Param('id') taskId: string, @CurrentUser() user: User) {
        // Try fetching by task ID first
        let task = await this.taskEngine.getTaskById(taskId);

        // If not found by taskId, try finding by orderId in available tasks
        if (!task) {
            try {
                const available = await this.taskEngine.getAvailableTasks(user.id);
                task = available.find((t: any) => 
                    t.orderId === taskId || t.id === taskId || t.campaignId === taskId
                );
            } catch (_) {}
        }

        if (!task) {
            throw new NotFoundException('Task not found');
        }

        // Only block access if the task is assigned to a DIFFERENT worker
        // Allow viewing if: unassigned and active/available, or assigned to current user
        const taskStatus = (task.status || '').toLowerCase();
        const isUnassigned = !task.assignedTo || task.assignedTo === '';
        const worker = await this.workerRepo.findWorker(user.id);
        const isAssignedToMe = task.assignedTo === user.id || (worker && task.assignedTo === worker.id);
        const isAvailable = isUnassigned && (taskStatus === 'active' || taskStatus === 'available' || taskStatus === 'pending');

        if (!isAssignedToMe && !isAvailable) {
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
        const worker = await this.workerRepo.findWorker(user.id);
        const isAssigned = task && (!task.assignedTo || task.assignedTo === user.id || (worker && task.assignedTo === worker.id));
        if (!task || !isAssigned) {
            throw new NotFoundException('Task not found');
        }

        const timeline: Array<{ status: string; timestamp: Date | string }> = [];

        if (task.createdAt) {
            timeline.push({ status: 'CREATED', timestamp: task.createdAt });
        }
        if (task.assignedAt) {
            timeline.push({ status: 'ASSIGNED', timestamp: task.assignedAt });
        }
        if (task.acceptedAt) {
            timeline.push({ status: 'ACCEPTED', timestamp: task.acceptedAt });
        }
        if (task.startedAt) {
            timeline.push({ status: 'IN_PROGRESS', timestamp: task.startedAt });
        }
        if (task.submittedAt) {
            timeline.push({ status: 'SUBMITTED', timestamp: task.submittedAt });
        }
        if (task.completedAt) {
            const finalStatus = (task.status || 'COMPLETED').toUpperCase();
            timeline.push({ status: finalStatus, timestamp: task.completedAt });
        } else if (task.status && !['created', 'assigned', 'accepted', 'in_progress', 'submitted'].includes(task.status.toLowerCase())) {
            timeline.push({ status: task.status.toUpperCase(), timestamp: task.updatedAt || new Date() });
        }

        timeline.sort((a, b) => new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime());

        return {
            success: true,
            taskId,
            timeline,
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
        // 1. Verify worker exists and is active
        const worker = await this.workerRepo.findWorker(user.id);
        if (!worker) {
            throw new BadRequestException('Worker profile not found');
        }
        if (worker.status && worker.status.toLowerCase() !== 'active') {
            throw new ForbiddenException(`Worker account is ${worker.status}. Only active workers can accept tasks.`);
        }

        // 2. Fetch the specific requested task (NO SILENT SWAP)
        const task = await this.taskEngine.getTaskById(taskId);
        if (!task) {
            throw new NotFoundException(`Task ${taskId} not found`);
        }

        // 3. Verify parent order is active (block accepting tasks from paused, cancelled, or completed campaigns)
        if (task.orderId) {
            const order = await this.orderRepo.findById(task.orderId);
            if (order) {
                const orderStatus = (order.status || '').toUpperCase();
                if (orderStatus === 'PAUSED') {
                    throw new BadRequestException('This order campaign is currently paused and cannot accept new workers');
                }
                if (orderStatus === 'CANCELLED' || orderStatus === 'COMPLETED' || orderStatus === 'EXPIRED') {
                    throw new BadRequestException(`This order campaign is ${orderStatus.toLowerCase()} and is no longer accepting tasks`);
                }
            }
        }

        // 4. Verify task availability / ownership
        if (task.assignedTo && task.assignedTo !== user.id && task.assignedTo !== worker.id) {
            throw new BadRequestException('Task is already assigned to another worker');
        }

        const taskStatus = (task.status || '').toLowerCase();
        if (taskStatus !== 'active' && taskStatus !== 'assigned' && taskStatus !== 'accepted') {
            throw new BadRequestException(`Task is not available for acceptance (current status: ${task.status})`);
        }

        // 4. Assign task if unassigned
        if (!task.assignedTo || taskStatus === 'active') {
            await this.taskEngine.assignTask({ taskId, workerId: user.id });
        }

        // 5. Accept task
        await this.taskEngine.acceptTask({ taskId, workerId: user.id });

        return {
            success: true,
            taskId,
            message: 'Task accepted successfully',
        };
    }

    @Post(':id/start')
    @ApiOperation({ summary: 'Start work on accepted task' })
    async startTask(@Param('id') taskId: string, @CurrentUser() user: User) {
        await this.executionEngine.startTaskExecution(taskId, user.id);
        return {
            success: true,
            message: 'Task started',
        };
    }

    @Post(':id/submit')
    @ApiOperation({ summary: 'Submit completed task with proof data' })
    async submitTask(
        @Param('id') taskId: string,
        @Body() body: { data: any; proofs: { fileId: string; url: string }[] },
        @CurrentUser() user: User,
    ) {
        if (!body.data || !body.proofs) {
            throw new BadRequestException('Invalid submission format. Expected { data: {}, proofs: [] }');
        }

        await this.executionEngine.submitTaskExecution(taskId, user.id, body);

        return {
            success: true,
            message: 'Task submitted for review',
        };
    }

    @Post(':id/resubmit')
    @ApiOperation({ summary: 'Resubmit task after addressing buyer/admin feedback' })
    async resubmitTask(
        @Param('id') taskId: string,
        @Body() body: { data: any; proofs: { fileId: string; url: string }[]; resubmissionNotes?: string },
        @CurrentUser() user: User,
    ) {
        await this.executionEngine.resubmitTaskExecution(taskId, user.id, body);

        return {
            success: true,
            message: 'Task resubmitted successfully for review',
        };
    }
}
