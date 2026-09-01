import { BadRequestException, Injectable, NotFoundException, Logger } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { Task } from '../../shared/database/entities/task.entity';
import { CampaignWorkerParticipation, ParticipationStatus } from '../../shared/database/entities/campaign-worker-participation.entity';
import { TaskAssignment, TaskAssignmentStatus } from '../../shared/database/entities/task-assignment.entity';
import { SystemSetting } from '../../shared/database/entities/system-settings.entity';
import { TaskRepository } from '../../shared/database/repositories/task.repository';
import { CampaignWorkerParticipationRepository } from '../../shared/database/repositories/campaign-worker-participation.repository';
import { TaskAssignmentRepository } from '../../shared/database/repositories/task-assignment.repository';
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
        private readonly dataSource: DataSource,
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
        return this.dataSource.transaction(async (manager) => {
            const task = await this.ensureTaskTransactional(manager, command.taskId);
            const campaignId = task.campaignId || task.orderId;

            const existingParticipation = await manager.findOne(CampaignWorkerParticipation, { where: { campaignId, workerId: command.workerId } });
            if (existingParticipation) {
                this.logger.warn(`Worker '${command.workerId}' has ALREADY participated in Campaign '${campaignId}' (Status: ${existingParticipation.status}). Cannot reassign same campaign task.`);
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
                    actor: { id: command.actorId || command.workerId, type: 'system' },
                });

                try {
                    const participation = manager.create(CampaignWorkerParticipation, { campaignId, workerId: command.workerId, status: ParticipationStatus.ASSIGNED });
                    await manager.save(participation);
                } catch (err) {
                    this.logger.warn(`DB UNIQUE CONFLICT: Worker '${command.workerId}' was assigned concurrently by another process in Campaign '${campaignId}'.`);
                    throw new BadRequestException(`Worker '${command.workerId}' participation conflict in Campaign '${campaignId}'`);
                }

                const attempts = await manager.find(TaskAssignment, { where: { taskId: task.id } });
                const assignment = manager.create(TaskAssignment, {
                    taskId: task.id,
                    campaignId,
                    workerId: command.workerId,
                    attemptNumber: attempts.length + 1,
                    status: TaskAssignmentStatus.ASSIGNED,
                    assignedAt: new Date(),
                });
                await manager.save(assignment);

                task.assignedTo = command.workerId;
                task.assignedAt = new Date();
                task.status = TaskStatus.ASSIGNED;
                task.metadata = { ...(task.metadata || {}), ...(command.metadata || {}) };
                return manager.save(task);
            }
            return task;
        });
    }

    async acceptTask(command: AcceptTaskCommand) {
        return this.dataSource.transaction(async (manager) => {
            const task = await this.ensureTaskTransactional(manager, command.taskId);
            this.validationService.ensureWorkerOwnership(task, command.workerId);

            if (task.status === TaskStatus.ACCEPTED && task.assignedTo === command.workerId) {
                return task;
            }

            if (task.status === TaskStatus.ACTIVE && !task.assignedTo) {
                const campaignId = task.campaignId || task.orderId;
                
                // 1. Verify worker has not already participated in this campaign
                const existingParticipation = await manager.findOne(CampaignWorkerParticipation, { where: { campaignId, workerId: command.workerId } });
                if (existingParticipation) {
                    throw new BadRequestException('You have already participated in this campaign. Each worker can only complete 1 task per campaign.');
                }

                // 2. Verify worker does not already hold another task for this campaign/order
                const existingTask = await manager.findOne(Task, {
                    where: [
                        { campaignId, assignedTo: command.workerId },
                        { orderId: task.orderId, assignedTo: command.workerId },
                    ],
                });
                if (existingTask && existingTask.id !== task.id) {
                    throw new BadRequestException('You have already taken a task for this order. Each worker can only complete 1 task per campaign.');
                }

                try {
                    const participation = manager.create(CampaignWorkerParticipation, { campaignId, workerId: command.workerId, status: ParticipationStatus.ASSIGNED });
                    await manager.save(participation);
                } catch (_) {}

                const attempts = await manager.find(TaskAssignment, { where: { taskId: task.id } });
                const assignment = manager.create(TaskAssignment, {
                    taskId: task.id,
                    campaignId,
                    workerId: command.workerId,
                    attemptNumber: attempts.length + 1,
                    status: TaskAssignmentStatus.ACCEPTED,
                    assignedAt: new Date(),
                    acceptedAt: new Date(),
                });
                await manager.save(assignment);

                // Dynamic deadline calculation from System Settings or task requirements
                let executionHours = 2.0;
                try {
                    const timeoutSetting = await manager.findOne(SystemSetting, { where: { key: 'worker_execution_timeout_hours' } });
                    if (timeoutSetting?.value) {
                        executionHours = Number(timeoutSetting.value);
                    }
                } catch (_) {}

                if (task.requirements?.timeToCompleteHours) {
                    executionHours = Number(task.requirements.timeToCompleteHours);
                }

                const now = new Date();
                const deadline = new Date(now.getTime() + executionHours * 3600 * 1000);

                task.status = TaskStatus.ACCEPTED;
                task.acceptedAt = now;
                task.assignedAt = now;
                task.assignedTo = command.workerId;
                task.deadline = deadline;
                return manager.save(task);
            }

            this.stateMachine.validateTransition({
                taskId: task.id,
                orderId: task.orderId,
                campaignId: task.campaignId,
                taskType: task.taskType,
                currentStatus: task.status,
                targetStatus: TaskStatus.ACCEPTED,
                timestamp: new Date(),
                actor: { id: command.workerId, type: 'worker' },
            });

            const activeAssignment = await this.findActiveAssignmentTransactional(manager, task.id);
            if (activeAssignment) {
                activeAssignment.acceptedAt = new Date();
                await manager.save(activeAssignment);
            }

            // Dynamic deadline calculation for pre-assigned task acceptance
            let executionHours = 2.0;
            try {
                const timeoutSetting = await manager.findOne(SystemSetting, { where: { key: 'worker_execution_timeout_hours' } });
                if (timeoutSetting?.value) {
                    executionHours = Number(timeoutSetting.value);
                }
            } catch (_) {}

            if (task.requirements?.timeToCompleteHours) {
                executionHours = Number(task.requirements.timeToCompleteHours);
            }

            const now = new Date();
            task.status = TaskStatus.ACCEPTED;
            task.acceptedAt = now;
            task.assignedTo = command.workerId;
            task.deadline = new Date(now.getTime() + executionHours * 3600 * 1000);
            return manager.save(task);
        });
    }

    async startTask(command: StartTaskCommand) {
        return this.dataSource.transaction(async (manager) => {
            const task = await this.ensureTaskTransactional(manager, command.taskId);
            this.validationService.ensureWorkerOwnership(task, command.workerId);

            if (task.status === TaskStatus.IN_PROGRESS) return task;

            this.stateMachine.validateTransition({
                taskId: task.id,
                orderId: task.orderId,
                campaignId: task.campaignId,
                taskType: task.taskType,
                currentStatus: task.status,
                targetStatus: TaskStatus.IN_PROGRESS,
                timestamp: new Date(),
                actor: { id: command.workerId, type: 'worker' },
            });

            task.status = TaskStatus.IN_PROGRESS;
            task.startedAt = new Date();
            task.assignedTo = command.workerId;
            return manager.save(task);
        });
    }

    async submitTask(command: SubmitTaskCommand) {
        return this.dataSource.transaction(async (manager) => {
            const task = await this.ensureTaskTransactional(manager, command.taskId);
            this.validationService.ensureWorkerOwnership(task, command.workerId);

            if (task.status === TaskStatus.SUBMITTED) return task;

            this.stateMachine.validateTransition({
                taskId: task.id,
                orderId: task.orderId,
                campaignId: task.campaignId,
                taskType: task.taskType,
                currentStatus: task.status,
                targetStatus: TaskStatus.SUBMITTED,
                timestamp: new Date(),
                actor: { id: command.workerId, type: 'worker' },
            });

            task.status = TaskStatus.SUBMITTED;
            task.submittedAt = new Date();
            task.metadata = { ...(task.metadata || {}), ...(command.metadata || {}), submissionData: command.data };
            return manager.save(task);
        });
    }

    async approveTask(command: ApproveTaskCommand) {
        return this.dataSource.transaction(async (manager) => {
            const task = await this.ensureTaskTransactional(manager, command.taskId);
            if (task.status === TaskStatus.APPROVED) return task;

            this.stateMachine.validateTransition({
                taskId: task.id,
                orderId: task.orderId,
                campaignId: task.campaignId,
                taskType: task.taskType,
                currentStatus: task.status,
                targetStatus: TaskStatus.APPROVED,
                timestamp: new Date(),
                actor: { id: command.reviewedBy || 'system', type: 'system' },
            });

            const campaignId = task.campaignId || task.orderId;
            if (task.assignedTo) {
                await manager.update(CampaignWorkerParticipation, { campaignId, workerId: task.assignedTo }, { status: ParticipationStatus.COMPLETED });
            }

            const activeAssignment = await this.findActiveAssignmentTransactional(manager, task.id);
            if (activeAssignment) {
                activeAssignment.status = TaskAssignmentStatus.COMPLETED;
                activeAssignment.completedAt = new Date();
                await manager.save(activeAssignment);
            }

            task.status = TaskStatus.APPROVED;
            task.completedAt = new Date();
            task.metadata = { ...(task.metadata || {}), reviewedBy: command.reviewedBy, reviewNotes: command.notes };
            return manager.save(task);
        });
    }

    async requestChangesTask(command: RequestChangesCommand) {
        return this.dataSource.transaction(async (manager) => {
            const task = await this.ensureTaskTransactional(manager, command.taskId);

            if (task.status !== TaskStatus.SUBMITTED && task.status !== TaskStatus.UNDER_REVIEW) {
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
                actor: { id: command.reviewedBy || 'system', type: 'system' },
            });

            task.status = TaskStatus.IN_PROGRESS;
            task.metadata = { ...(task.metadata || {}), reviewedBy: command.reviewedBy, reviewNotes: command.notes, changesRequestedAt: new Date() };
            return manager.save(task);
        });
    }

    async rejectTask(command: RejectTaskCommand) {
        return this.dataSource.transaction(async (manager) => {
            const task = await this.ensureTaskTransactional(manager, command.taskId);
            if (task.status === TaskStatus.REJECTED) return task;

            if (task.status !== TaskStatus.SUBMITTED && task.status !== TaskStatus.UNDER_REVIEW) {
                throw new BadRequestException('Task is not ready for rejection');
            }

            this.stateMachine.validateTransition({
                taskId: task.id,
                orderId: task.orderId,
                campaignId: task.campaignId,
                taskType: task.taskType,
                currentStatus: task.status,
                targetStatus: TaskStatus.REJECTED,
                timestamp: new Date(),
                actor: { id: command.reviewedBy || 'system', type: 'system' },
            });

            const campaignId = task.campaignId || task.orderId;
            if (task.assignedTo) {
                await manager.update(CampaignWorkerParticipation, { campaignId, workerId: task.assignedTo }, { status: ParticipationStatus.REJECTED });
            }

            const activeAssignment = await this.findActiveAssignmentTransactional(manager, task.id);
            if (activeAssignment) {
                activeAssignment.status = TaskAssignmentStatus.REJECTED;
                await manager.save(activeAssignment);
            }

            task.status = TaskStatus.REJECTED;
            task.metadata = { ...(task.metadata || {}), reviewedBy: command.reviewedBy, reviewNotes: command.notes };
            return manager.save(task);
        });
    }

    async cancelTask(command: CancelTaskCommand) {
        return this.dataSource.transaction(async (manager) => {
            const task = await this.ensureTaskTransactional(manager, command.taskId);
            if (task.status === TaskStatus.CANCELLED || task.status === TaskStatus.APPROVED) return task;

            this.stateMachine.validateTransition({
                taskId: task.id,
                orderId: task.orderId,
                campaignId: task.campaignId,
                taskType: task.taskType,
                currentStatus: task.status,
                targetStatus: TaskStatus.CANCELLED,
                timestamp: new Date(),
                actor: { id: command.actorId || 'system', type: 'system' },
            });

            task.status = TaskStatus.CANCELLED;
            task.metadata = { ...(task.metadata || {}), cancellationReason: command.reason, cancelledBy: command.actorId };
            return manager.save(task);
        });
    }

    private async ensureTaskTransactional(manager: any, taskId: string) {
        const task = await manager.findOne(Task, {
            where: { id: taskId },
            lock: { mode: 'pessimistic_write' }
        });
        if (!task) {
            throw new NotFoundException('Task not found');
        }
        return task;
    }

    private async findActiveAssignmentTransactional(manager: any, taskId: string) {
        return manager.findOne(TaskAssignment, {
            where: [
                { taskId, status: TaskAssignmentStatus.ASSIGNED },
                { taskId, status: TaskAssignmentStatus.ACCEPTED },
                { taskId, status: TaskAssignmentStatus.STARTED },
                { taskId, status: TaskAssignmentStatus.SUBMITTED },
            ],
            order: { attemptNumber: 'DESC' },
        });
    }
}
