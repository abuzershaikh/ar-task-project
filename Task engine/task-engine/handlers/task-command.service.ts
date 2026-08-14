import { BadRequestException, Injectable, NotFoundException, Logger } from '@nestjs/common';
import { TaskRepository } from '../../shared/database/repositories/task.repository';
import { CampaignWorkerParticipationRepository } from '../../shared/database/repositories/campaign-worker-participation.repository';
import { TaskAssignmentRepository } from '../../shared/database/repositories/task-assignment.repository';
import { ParticipationStatus } from '../../shared/database/entities/campaign-worker-participation.entity';
import { TaskAssignmentStatus } from '../../shared/database/entities/task-assignment.entity';
import { TaskValidationService } from '../task-validation.service';
import { TaskStateMachine } from '../state-machine/task-state-machine';
import { TaskStatus } from '../types/task-status.enum';
import { CreateTaskCommand } from '../commands/create-task.command';
import { AssignTaskCommand } from '../commands/assign-task.command';
import { AcceptTaskCommand } from '../commands/accept-task.command';
import { StartTaskCommand } from '../commands/start-task.command';
import { SubmitTaskCommand } from '../commands/submit-task.command';
import { ApproveTaskCommand } from '../commands/approve-task.command';
import { RejectTaskCommand } from '../commands/reject-task.command';
import { RequestChangesCommand } from '../commands/request-changes.command';
import { CancelTaskCommand } from '../commands/cancel-task.command';

@Injectable()
export class TaskCommandService {
    private readonly logger = new Logger(TaskCommandService.name);

    constructor(
        private readonly taskRepository: TaskRepository,
        private readonly participationRepo: CampaignWorkerParticipationRepository,
        private readonly assignmentRepo: TaskAssignmentRepository,
        private readonly validationService: TaskValidationService,
        private readonly stateMachine: TaskStateMachine,
    ) { }

    async createTask(command: CreateTaskCommand) {
        return this.taskRepository.create({
            orderId: command.orderId,
            campaignId: command.campaignId || command.orderId,
            taskType: command.taskType,
            rewardAmount: command.rewardAmount,
            requirements: command.requirements,
            metadata: command.metadata,
            deadline: command.deadline,
            status: command.status || TaskStatus.ACTIVE,
        });
    }

    async assignTask(command: AssignTaskCommand) {
        const task = await this.ensureTask(command.taskId);
        const campaignId = task.campaignId || task.orderId;

        // Protection Pillar: Check if worker has ALREADY participated in this Campaign
        const existingParticipation = await this.participationRepo.findByCampaignAndWorker(campaignId, command.workerId);
        if (existingParticipation) {
            this.logger.warn(
                `Worker '${command.workerId}' has ALREADY participated in Campaign '${campaignId}' (Status: ${existingParticipation.status}). Cannot reassign same campaign task.`,
            );
            throw new BadRequestException(`Worker has already participated in Campaign '${campaignId}'`);
        }

        if (task.assignedTo && task.assignedTo !== command.workerId) {
            throw new BadRequestException('Task is already assigned to another worker');
        }

        if (!task.assignedTo) {
            this.validationService.ensureTaskAssignable(task);
            this.stateMachine.validateTransition({
                taskId: task.id,
                orderId: task.orderId,
                campaignId: task.campaignId,
                taskType: task.taskType,
                currentStatus: task.status,
                targetStatus: TaskStatus.ASSIGNED,
                timestamp: new Date(),
                actor: {
                    id: command.actorId || command.workerId,
                    type: 'system',
                },
            });

            // 1. Record Campaign Worker Participation (UNIQUE DB Constraint Guard against race conditions)
            try {
                await this.participationRepo.recordParticipation(campaignId, command.workerId, ParticipationStatus.ASSIGNED);
            } catch (err) {
                this.logger.warn(
                    `DB UNIQUE CONFLICT: Worker '${command.workerId}' was assigned concurrently by another process in Campaign '${campaignId}'. Discarding candidate worker.`,
                );
                throw new BadRequestException(`Worker '${command.workerId}' participation conflict in Campaign '${campaignId}'`);
            }

            // 2. Record Task Assignment History
            await this.assignmentRepo.createAssignment({
                taskId: task.id,
                campaignId,
                workerId: command.workerId,
            });

            return this.taskRepository.update(task.id, {
                assignedTo: command.workerId,
                assignedAt: new Date(),
                status: TaskStatus.ASSIGNED,
                metadata: {
                    ...(task.metadata || {}),
                    ...(command.metadata || {}),
                },
            });
        }

        return task;
    }

    async acceptTask(command: AcceptTaskCommand) {
        const task = await this.ensureTask(command.taskId);
        this.validationService.ensureWorkerOwnership(task, command.workerId);

        if (task.status === TaskStatus.ACCEPTED && task.assignedTo === command.workerId) {
            return task;
        }

        if (task.status === TaskStatus.ACTIVE && !task.assignedTo) {
            await this.assignTask({
                taskId: task.id,
                workerId: command.workerId,
            });
        }

        const assignedTask = await this.ensureTask(command.taskId);
        this.validationService.ensureWorkerOwnership(assignedTask, command.workerId);

        this.stateMachine.validateTransition({
            taskId: assignedTask.id,
            orderId: assignedTask.orderId,
            campaignId: assignedTask.campaignId,
            taskType: assignedTask.taskType,
            currentStatus: assignedTask.status,
            targetStatus: TaskStatus.ACCEPTED,
            timestamp: new Date(),
            actor: {
                id: command.workerId,
                type: 'worker',
            },
        });

        const activeAssignment = await this.assignmentRepo.findActiveAssignment(command.taskId);
        if (activeAssignment) {
            await this.assignmentRepo.updateStatus(activeAssignment.id, activeAssignment.status, { acceptedAt: new Date() });
        }

        return this.taskRepository.update(assignedTask.id, {
            status: TaskStatus.ACCEPTED,
            acceptedAt: new Date(),
            assignedTo: command.workerId,
        });
    }

    async startTask(command: StartTaskCommand) {
        const task = await this.ensureTask(command.taskId);
        this.validationService.ensureWorkerOwnership(task, command.workerId);

        if (task.status === TaskStatus.IN_PROGRESS) {
            return task;
        }

        this.stateMachine.validateTransition({
            taskId: task.id,
            orderId: task.orderId,
            campaignId: task.campaignId,
            taskType: task.taskType,
            currentStatus: task.status,
            targetStatus: TaskStatus.IN_PROGRESS,
            timestamp: new Date(),
            actor: {
                id: command.workerId,
                type: 'worker',
            },
        });

        return this.taskRepository.update(task.id, {
            status: TaskStatus.IN_PROGRESS,
            startedAt: new Date(),
            assignedTo: command.workerId,
        });
    }

    async submitTask(command: SubmitTaskCommand) {
        const task = await this.ensureTask(command.taskId);
        this.validationService.ensureWorkerOwnership(task, command.workerId);

        if (task.status === TaskStatus.SUBMITTED) {
            return task;
        }

        this.stateMachine.validateTransition({
            taskId: task.id,
            orderId: task.orderId,
            campaignId: task.campaignId,
            taskType: task.taskType,
            currentStatus: task.status,
            targetStatus: TaskStatus.SUBMITTED,
            timestamp: new Date(),
            actor: {
                id: command.workerId,
                type: 'worker',
            },
        });

        return this.taskRepository.update(task.id, {
            status: TaskStatus.SUBMITTED,
            submittedAt: new Date(),
            metadata: {
                ...(task.metadata || {}),
                ...(command.metadata || {}),
                submissionData: command.data,
            },
        });
    }

    async approveTask(command: ApproveTaskCommand) {
        const task = await this.ensureTask(command.taskId);
        if (task.status === TaskStatus.APPROVED) {
            return task;
        }

        if (
            task.status !== TaskStatus.SUBMITTED &&
            task.status !== TaskStatus.UNDER_REVIEW &&
            task.status !== TaskStatus.REJECTED
        ) {
            throw new BadRequestException('Task is not ready for approval');
        }

        const campaignId = task.campaignId || task.orderId;
        if (task.assignedTo) {
            await this.participationRepo.updateStatus(campaignId, task.assignedTo, ParticipationStatus.COMPLETED);
        }

        const activeAssignment = await this.assignmentRepo.findActiveAssignment(task.id);
        if (activeAssignment) {
            await this.assignmentRepo.updateStatus(activeAssignment.id, TaskAssignmentStatus.COMPLETED, {
                completedAt: new Date(),
            });
        }

        return this.taskRepository.update(task.id, {
            status: TaskStatus.APPROVED,
            completedAt: new Date(),
            metadata: {
                ...(task.metadata || {}),
                reviewedBy: command.reviewedBy,
                reviewNotes: command.notes,
            },
        });
    }

    async requestChangesTask(command: RequestChangesCommand) {
        const task = await this.ensureTask(command.taskId);

        if (
            task.status !== TaskStatus.SUBMITTED &&
            task.status !== TaskStatus.UNDER_REVIEW
        ) {
            throw new BadRequestException('Task is not ready for requesting changes');
        }

        this.stateMachine.validateTransition({
            taskId: task.id,
            orderId: task.orderId,
            campaignId: task.campaignId,
            taskType: task.taskType,
            currentStatus: task.status,
            targetStatus: TaskStatus.IN_PROGRESS,
            timestamp: new Date(),
            actor: {
                id: command.reviewedBy || 'system',
                type: 'system',
            },
        });

        return this.taskRepository.update(task.id, {
            status: TaskStatus.IN_PROGRESS,
            metadata: {
                ...(task.metadata || {}),
                reviewedBy: command.reviewedBy,
                reviewNotes: command.notes,
                changesRequestedAt: new Date()
            },
        });
    }

    async rejectTask(command: RejectTaskCommand) {
        const task = await this.ensureTask(command.taskId);
        if (task.status === TaskStatus.REJECTED) {
            return task;
        }

        if (
            task.status !== TaskStatus.SUBMITTED &&
            task.status !== TaskStatus.UNDER_REVIEW
        ) {
            throw new BadRequestException('Task is not ready for rejection');
        }

        const campaignId = task.campaignId || task.orderId;
        if (task.assignedTo) {
            // Worker is rejected, but participation record remains so worker is excluded from this campaign!
            await this.participationRepo.updateStatus(campaignId, task.assignedTo, ParticipationStatus.REJECTED);
        }

        const activeAssignment = await this.assignmentRepo.findActiveAssignment(task.id);
        if (activeAssignment) {
            await this.assignmentRepo.updateStatus(activeAssignment.id, TaskAssignmentStatus.REJECTED);
        }

        return this.taskRepository.update(task.id, {
            status: TaskStatus.REJECTED,
            metadata: {
                ...(task.metadata || {}),
                reviewedBy: command.reviewedBy,
                reviewNotes: command.notes,
            },
        });
    }

    async cancelTask(command: CancelTaskCommand) {
        const task = await this.ensureTask(command.taskId);

        if (task.status === TaskStatus.CANCELLED || task.status === TaskStatus.APPROVED) {
            return task;
        }

        return this.taskRepository.update(task.id, {
            status: TaskStatus.CANCELLED,
            metadata: {
                ...(task.metadata || {}),
                cancellationReason: command.reason,
                cancelledBy: command.actorId,
            },
        });
    }

    private async ensureTask(taskId: string) {
        const task = await this.taskRepository.findById(taskId);
        if (!task) {
            throw new NotFoundException('Task not found');
        }
        return task;
    }
}
