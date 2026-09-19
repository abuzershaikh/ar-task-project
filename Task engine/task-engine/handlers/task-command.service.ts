import { BadRequestException, Injectable, NotFoundException, Logger } from '@nestjs/common';
import { DataSource, In } from 'typeorm';
import { Task } from '../../shared/database/entities/task.entity';
import { CampaignWorkerParticipation, ParticipationStatus } from '../../shared/database/entities/campaign-worker-participation.entity';
import { TaskAssignment, TaskAssignmentStatus } from '../../shared/database/entities/task-assignment.entity';
import { SystemSetting } from '../../shared/database/entities/system-settings.entity';
import { User } from '../../shared/database/entities/user.entity';
import { Worker } from '../../shared/database/entities/worker.entity';
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
import { extractTaskIdentity } from '../../shared/common/utils/task-identity.util';

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

    private async resolveWorkerIdentifiers(manager: any, workerId: string, workerEmail?: string): Promise<{ email: string; allIds: string[] }> {
        const ids = new Set<string>();
        let resolvedEmail = (workerEmail || '').toLowerCase().trim();

        if (workerId) {
            ids.add(workerId);
            if (workerId.includes('@')) {
                resolvedEmail = workerId.toLowerCase().trim();
            }
        }

        // 1. If workerId matches Worker profile UUID or User ID
        try {
            const workerProfile = await manager.findOne(Worker, {
                where: [{ id: workerId }, { userId: workerId }],
            });
            if (workerProfile) {
                if (workerProfile.id) ids.add(workerProfile.id);
                if (workerProfile.userId) {
                    ids.add(workerProfile.userId);
                    if (!resolvedEmail) {
                        const user = await manager.findOne(User, { where: { id: workerProfile.userId } });
                        if (user?.email) resolvedEmail = user.email.toLowerCase().trim();
                    }
                }
            }
        } catch (_) {}

        // 2. Lookup by User ID
        if (!resolvedEmail && workerId) {
            try {
                const user = await manager.findOne(User, { where: { id: workerId } });
                if (user?.email) {
                    resolvedEmail = user.email.toLowerCase().trim();
                }
                if (user?.id) ids.add(user.id);
            } catch (_) {}
        }

        // 3. Lookup by resolvedEmail
        if (resolvedEmail) {
            ids.add(resolvedEmail);
            try {
                const user = await manager.findOne(User, { where: { email: resolvedEmail } });
                if (user?.id) {
                    ids.add(user.id);
                    const workerProfile = await manager.findOne(Worker, { where: { userId: user.id } });
                    if (workerProfile?.id) ids.add(workerProfile.id);
                }
            } catch (_) {}
        }

        return { email: resolvedEmail, allIds: Array.from(ids) };
    }

    private async acquireIdentityLock(manager: any, workerKey: string, entityKey?: string): Promise<string | null> {
        if (!entityKey || !workerKey) return null;
        const crypto = require('crypto');
        const rawName = `t_lock:${workerKey.toLowerCase().trim()}:${entityKey.toLowerCase().trim()}`;
        const hash = crypto.createHash('md5').update(rawName).digest('hex');
        const lockName = `t_lock_${hash}`;
        try {
            const res = await manager.query('SELECT GET_LOCK(?, 10) AS acquired', [lockName]);
            const acquired = res?.[0]?.acquired;
            if (acquired !== 1 && acquired !== true && acquired !== '1') {
                this.logger.error(`Fail-closed: Could not acquire lock for ${lockName} within 10s`);
                throw new BadRequestException('Another task operation is currently in progress for this app/URL. Please retry.');
            }
            return lockName;
        } catch (e: any) {
            if (e instanceof BadRequestException) throw e;
            this.logger.error(`Fail-closed: Error acquiring identity lock ${lockName}: ${e?.message}`);
            throw new BadRequestException('Could not acquire concurrency lock. Please retry.');
        }
    }

    private async releaseIdentityLock(manager: any, lockName: string | null) {
        if (!lockName) return;
        try {
            await manager.query('SELECT RELEASE_LOCK(?)', [lockName]);
        } catch (err: any) {
            this.logger.warn(`Error releasing advisory lock ${lockName}: ${err?.message}`);
        }
    }

    private async recordWorkerCompletedIdentity(
        manager: any,
        workerAliases: string[],
        entityKey: string,
        taskId: string,
    ): Promise<void> {
        if (!entityKey || !workerAliases || workerAliases.length === 0) return;
        const cleanEntity = entityKey.toLowerCase().trim();

        for (const alias of workerAliases) {
            const cleanAlias = (alias || '').toLowerCase().trim();
            if (!cleanAlias) continue;
            try {
                await manager.query(
                    `INSERT INTO worker_completed_identities (worker_key, entity_key, task_id) VALUES (?, ?, ?)`,
                    [cleanAlias, cleanEntity, taskId],
                );
            } catch (dupErr: any) {
                if (dupErr?.code === 'ER_DUP_ENTRY' || dupErr?.errno === 1062) {
                    throw new BadRequestException('You have already completed or attempted a task for this app/URL.');
                }
                // If table doesn't exist yet, we log and do not crash
                this.logger.warn(`Could not insert into worker_completed_identities: ${dupErr?.message}`);
            }
        }
    }

    private async verifyNoDuplicateAppOrUrlTransactional(
        manager: any,
        task: Task,
        allIds: string[],
        targetIdentity: any,
    ) {
        if (!targetIdentity.packageId && !targetIdentity.normalizedUrl && !targetIdentity.entityKey) return;

        // 1. Check physical DB unique constraint table
        if (targetIdentity.entityKey) {
            try {
                const dupRows = await manager.query(
                    `SELECT id FROM worker_completed_identities WHERE worker_key IN (?) AND entity_key = ? LIMIT 1`,
                    [allIds, targetIdentity.entityKey.toLowerCase().trim()],
                );
                if (dupRows && dupRows.length > 0) {
                    throw new BadRequestException('You have already completed or attempted a task for this app/URL.');
                }
            } catch (err: any) {
                if (err instanceof BadRequestException) throw err;
                this.logger.warn(`Could not check worker_completed_identities table: ${err?.message}`);
            }
        }

        // 2. Current active assigned tasks
        const workerTasks = await manager.find(Task, {
            where: { assignedTo: In(allIds) },
        });

        // 3. Historical assignments across ALL statuses (expired, released, rejected, completed)
        const workerAssignments = await manager.find(TaskAssignment, {
            where: { workerId: In(allIds) },
        });
        const historicalTaskIds = workerAssignments
            .map((a: any) => a.taskId)
            .filter((id: string) => id && id !== task.id);

        let allTasksToCheck: Task[] = [...workerTasks];
        if (historicalTaskIds.length > 0) {
            const historicalTasks = await manager.find(Task, {
                where: { id: In(historicalTaskIds) },
            });
            allTasksToCheck = allTasksToCheck.concat(historicalTasks);
        }

        const checkedTaskIds = new Set<string>();
        for (const wt of allTasksToCheck) {
            if (wt.id === task.id || checkedTaskIds.has(wt.id)) continue;
            checkedTaskIds.add(wt.id);

            const pastIdentity = extractTaskIdentity(wt);
            if (targetIdentity.packageId && pastIdentity.packageId === targetIdentity.packageId) {
                throw new BadRequestException('You have already completed or accepted a task for this app.');
            }
            if (targetIdentity.normalizedUrl && pastIdentity.normalizedUrl === targetIdentity.normalizedUrl) {
                throw new BadRequestException('You have already completed or accepted a task for this link/URL.');
            }
        }
    }

    async createTask(command: CreateTaskCommand) {
        return this.taskRepository.create({
            orderId: command.orderId,
            campaignId: command.campaignId || command.orderId,
            orderUnitId: command.orderUnitId || command.requirements?.orderUnitId || null,
            taskType: command.taskType,
            rewardAmount: command.rewardAmount,
            requirements: command.requirements,
            metadata: command.metadata,
            deadline: command.deadline,
            status: command.status || TaskStatus.ACTIVE,
        });
    }

    async assignTask(command: AssignTaskCommand) {
        const queryRunner = this.dataSource.createQueryRunner();
        await queryRunner.connect();

        let lockName: string | null = null;
        try {
            const task = await this.ensureTaskTransactional(queryRunner.manager, command.taskId);
            const campaignId = task.campaignId || task.orderId;
            const orderId = task.orderId || task.campaignId;
            const orderUnitId = task.orderUnitId || (command as any).orderUnitId || task.requirements?.orderUnitId || null;

            const { email: workerEmail, allIds } = await this.resolveWorkerIdentifiers(queryRunner.manager, command.workerId, command.workerEmail);
            const primaryWorkerKey = workerEmail || command.workerId;
            const targetIdentity = extractTaskIdentity(task);

            // Acquire advisory lock on the dedicated connection BEFORE starting transaction!
            lockName = await this.acquireIdentityLock(queryRunner.manager, primaryWorkerKey, targetIdentity.entityKey);

            await queryRunner.startTransaction();
            const manager = queryRunner.manager;

            // 1. Same campaign participation verification
            const existingParticipation = await manager.findOne(CampaignWorkerParticipation, {
                where: [
                    { campaignId, workerId: In(allIds) },
                    ...(orderId !== campaignId ? [{ campaignId: orderId, workerId: In(allIds) }] : [])
                ]
            });
            if (existingParticipation) {
                this.logger.warn(`Worker '${primaryWorkerKey}' has ALREADY participated in Campaign '${campaignId}'. Cannot assign same campaign task.`);
                throw new BadRequestException('You have already participated in this campaign.');
            }

            // 2. Same exact task protection
            const existingTaskAssignment = await manager.findOne(TaskAssignment, {
                where: { taskId: task.id, workerId: In(allIds) }
            });
            if (existingTaskAssignment) {
                throw new BadRequestException('This task has already been assigned to you.');
            }

            // 3. Same unit protection
            if (orderUnitId) {
                const existingUnitAssignment = await manager.findOne(TaskAssignment, {
                    where: { orderUnitId, workerId: In(allIds) }
                });
                if (existingUnitAssignment) {
                    throw new BadRequestException('This task unit has already been assigned.');
                }
            }

            // 4. Same App Package & Same URL Protection across all campaigns with concurrency lock
            await this.verifyNoDuplicateAppOrUrlTransactional(manager, task, allIds, targetIdentity);

            if (task.assignedTo && !allIds.includes(task.assignedTo)) {
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
                    actor: { id: command.actorId || primaryWorkerKey, type: 'system' },
                });

                try {
                    const participation = manager.create(CampaignWorkerParticipation, {
                        campaignId,
                        workerId: primaryWorkerKey,
                        status: ParticipationStatus.ASSIGNED,
                    });
                    await manager.save(participation);
                } catch (err) {
                    this.logger.warn(`DB UNIQUE CONFLICT: Worker '${primaryWorkerKey}' was assigned concurrently in Campaign '${campaignId}'.`);
                    throw new BadRequestException('You have already participated in this campaign.');
                }

                // Insert into worker_completed_identities for DB-level physical unique constraint
                if (targetIdentity.entityKey) {
                    await this.recordWorkerCompletedIdentity(manager, allIds, targetIdentity.entityKey, task.id);
                }

                const attempts = await manager.find(TaskAssignment, { where: { taskId: task.id } });
                const assignment = manager.create(TaskAssignment, {
                    taskId: task.id,
                    campaignId,
                    orderId,
                    orderUnitId,
                    workerId: primaryWorkerKey,
                    attemptNumber: attempts.length + 1,
                    status: TaskAssignmentStatus.ASSIGNED,
                    assignedAt: new Date(),
                });
                await manager.save(assignment);

                task.assignedTo = primaryWorkerKey;
                task.orderUnitId = orderUnitId;
                task.assignedAt = new Date();
                task.status = TaskStatus.ASSIGNED;
                task.metadata = { ...(task.metadata || {}), ...(command.metadata || {}) };
                const saved = await manager.save(task);

                await queryRunner.commitTransaction();
                return saved;
            }

            await queryRunner.commitTransaction();
            return task;
        } catch (err) {
            if (queryRunner.isTransactionActive) {
                await queryRunner.rollbackTransaction();
            }
            throw err;
        } finally {
            if (lockName) {
                await this.releaseIdentityLock(queryRunner.manager, lockName);
            }
            await queryRunner.release();
        }
    }

    async acceptTask(command: AcceptTaskCommand) {
        const queryRunner = this.dataSource.createQueryRunner();
        await queryRunner.connect();

        let lockName: string | null = null;
        try {
            const task = await this.ensureTaskTransactional(queryRunner.manager, command.taskId);
            const { email: workerEmail, allIds } = await this.resolveWorkerIdentifiers(queryRunner.manager, command.workerId, command.workerEmail);
            const primaryWorkerKey = workerEmail || command.workerId;
            const campaignId = task.campaignId || task.orderId;
            const orderId = task.orderId || task.campaignId;
            const orderUnitId = task.orderUnitId || (command as any).orderUnitId || task.requirements?.orderUnitId || null;
            const targetIdentity = extractTaskIdentity(task);

            if (task.assignedTo && !allIds.includes(task.assignedTo)) {
                throw new BadRequestException('Task is already assigned to another worker');
            }

            if (task.status === TaskStatus.ACCEPTED && allIds.includes(task.assignedTo || '')) {
                return task;
            }

            // Acquire advisory lock on the dedicated connection BEFORE starting transaction!
            lockName = await this.acquireIdentityLock(queryRunner.manager, primaryWorkerKey, targetIdentity.entityKey);

            await queryRunner.startTransaction();
            const manager = queryRunner.manager;

            // Perform 3-level verification if task was unassigned or active
            if (!task.assignedTo || task.status === TaskStatus.ACTIVE) {
                // 1. Same campaign participation verification
                const existingParticipation = await manager.findOne(CampaignWorkerParticipation, {
                    where: [
                        { campaignId, workerId: In(allIds) },
                        ...(orderId !== campaignId ? [{ campaignId: orderId, workerId: In(allIds) }] : [])
                    ]
                });
                if (existingParticipation) {
                    throw new BadRequestException('You have already participated in this campaign.');
                }

                // 2. Same exact task protection
                const existingTaskAssignment = await manager.findOne(TaskAssignment, {
                    where: { taskId: task.id, workerId: In(allIds) }
                });
                if (existingTaskAssignment) {
                    throw new BadRequestException('This task has already been assigned to you.');
                }

                // 3. Same unit protection
                if (orderUnitId) {
                    const existingUnitAssignment = await manager.findOne(TaskAssignment, {
                        where: { orderUnitId, workerId: In(allIds) }
                    });
                    if (existingUnitAssignment) {
                        throw new BadRequestException('This task unit has already been assigned.');
                    }

                    // Check if another worker is actively holding this unit
                    const activeUnitHolder = await manager.findOne(TaskAssignment, {
                        where: [
                            { orderUnitId, status: TaskAssignmentStatus.ASSIGNED },
                            { orderUnitId, status: TaskAssignmentStatus.ACCEPTED },
                            { orderUnitId, status: TaskAssignmentStatus.STARTED },
                            { orderUnitId, status: TaskAssignmentStatus.SUBMITTED },
                        ]
                    });
                    if (activeUnitHolder && !allIds.includes(activeUnitHolder.workerId)) {
                        throw new BadRequestException('This task unit has already been assigned.');
                    }
                }

                // Verify worker does not already hold another task for this campaign/order
                const existingTask = await manager.findOne(Task, {
                    where: [
                        { campaignId, assignedTo: In(allIds) },
                        { orderId, assignedTo: In(allIds) },
                    ],
                });
                if (existingTask && existingTask.id !== task.id) {
                    throw new BadRequestException('You have already participated in this campaign.');
                }

                // 4. Same App Package & Same URL Protection across all campaigns with concurrency lock
                await this.verifyNoDuplicateAppOrUrlTransactional(manager, task, allIds, targetIdentity);

                try {
                    const participation = manager.create(CampaignWorkerParticipation, {
                        campaignId,
                        workerId: primaryWorkerKey,
                        status: ParticipationStatus.ASSIGNED,
                    });
                    await manager.save(participation);
                } catch (partErr) {
                    this.logger.warn(`CampaignWorkerParticipation constraint conflict: ${partErr?.message}`);
                    throw new BadRequestException('You have already participated in this campaign.');
                }

                // Insert into worker_completed_identities for DB-level physical unique constraint
                if (targetIdentity.entityKey) {
                    await this.recordWorkerCompletedIdentity(manager, allIds, targetIdentity.entityKey, task.id);
                }

                const attempts = await manager.find(TaskAssignment, { where: { taskId: task.id } });
                const assignment = manager.create(TaskAssignment, {
                    taskId: task.id,
                    campaignId,
                    orderId,
                    orderUnitId,
                    workerId: primaryWorkerKey,
                    attemptNumber: attempts.length + 1,
                    status: TaskAssignmentStatus.ACCEPTED,
                    assignedAt: new Date(),
                    acceptedAt: new Date(),
                });
                await manager.save(assignment);

                // Dynamic deadline calculation: Strictly prioritize Admin system setting
                let executionHours = 2.0;
                try {
                    const timeoutSetting = await manager.findOne(SystemSetting, { where: { key: 'worker_execution_timeout_hours' } });
                    if (timeoutSetting && timeoutSetting.value !== null && timeoutSetting.value !== undefined) {
                        executionHours = Number(timeoutSetting.value);
                    } else if (task.requirements?.timeToCompleteHours) {
                        executionHours = Number(task.requirements.timeToCompleteHours);
                    }
                } catch (_) {
                    if (task.requirements?.timeToCompleteHours) {
                        executionHours = Number(task.requirements.timeToCompleteHours);
                    }
                }

                const now = new Date();
                const deadline = new Date(now.getTime() + executionHours * 3600 * 1000);

                task.status = TaskStatus.ACCEPTED;
                task.acceptedAt = now;
                task.assignedAt = now;
                task.assignedTo = primaryWorkerKey;
                task.orderUnitId = orderUnitId;
                task.deadline = deadline;
                const saved = await manager.save(task);

                await queryRunner.commitTransaction();
                return saved;
            }

            // If task was already assigned to this worker, transition to ACCEPTED
            this.stateMachine.validateTransition({
                taskId: task.id,
                orderId: task.orderId,
                campaignId: task.campaignId,
                taskType: task.taskType,
                currentStatus: task.status,
                targetStatus: TaskStatus.ACCEPTED,
                timestamp: new Date(),
                actor: { id: primaryWorkerKey, type: 'worker' },
            });

            const activeAssignment = await this.findActiveAssignmentTransactional(manager, task.id);
            if (activeAssignment) {
                activeAssignment.acceptedAt = new Date();
                activeAssignment.status = TaskAssignmentStatus.ACCEPTED;
                await manager.save(activeAssignment);
            }

            // Dynamic deadline calculation for pre-assigned task acceptance
            let executionHours = 2.0;
            try {
                const timeoutSetting = await manager.findOne(SystemSetting, { where: { key: 'worker_execution_timeout_hours' } });
                if (timeoutSetting && timeoutSetting.value !== null && timeoutSetting.value !== undefined) {
                    executionHours = Number(timeoutSetting.value);
                } else if (task.requirements?.timeToCompleteHours) {
                    executionHours = Number(task.requirements.timeToCompleteHours);
                }
            } catch (_) {
                if (task.requirements?.timeToCompleteHours) {
                    executionHours = Number(task.requirements.timeToCompleteHours);
                }
            }

            const now = new Date();
            task.status = TaskStatus.ACCEPTED;
            task.acceptedAt = now;
            task.assignedTo = primaryWorkerKey;
            task.orderUnitId = orderUnitId;
            task.deadline = new Date(now.getTime() + executionHours * 3600 * 1000);
            const saved = await manager.save(task);

            await queryRunner.commitTransaction();
            return saved;
        } catch (err) {
            if (queryRunner.isTransactionActive) {
                await queryRunner.rollbackTransaction();
            }
            throw err;
        } finally {
            if (lockName) {
                await this.releaseIdentityLock(queryRunner.manager, lockName);
            }
            await queryRunner.release();
        }
    }

    async startTask(command: StartTaskCommand) {
        return this.dataSource.transaction(async (manager) => {
            const task = await this.ensureTaskTransactional(manager, command.taskId);
            const { allIds } = await this.resolveWorkerIdentifiers(manager, command.workerId, command.workerEmail);
            this.validationService.ensureWorkerOwnership(task, command.workerId, command.workerEmail, allIds);

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

            const activeAssignment = await this.findActiveAssignmentTransactional(manager, task.id);
            if (activeAssignment) {
                activeAssignment.startedAt = new Date();
                activeAssignment.status = TaskAssignmentStatus.STARTED;
                await manager.save(activeAssignment);
            }

            task.status = TaskStatus.IN_PROGRESS;
            task.startedAt = new Date();
            return manager.save(task);
        });
    }

    async submitTask(command: SubmitTaskCommand) {
        return this.dataSource.transaction(async (manager) => {
            const task = await this.ensureTaskTransactional(manager, command.taskId);
            const { allIds } = await this.resolveWorkerIdentifiers(manager, command.workerId, command.workerEmail);
            this.validationService.ensureWorkerOwnership(task, command.workerId, command.workerEmail, allIds);

            if (task.status === TaskStatus.UNDER_REVIEW) return task;

            this.stateMachine.validateTransition({
                taskId: task.id,
                orderId: task.orderId,
                campaignId: task.campaignId,
                taskType: task.taskType,
                currentStatus: task.status,
                targetStatus: TaskStatus.UNDER_REVIEW,
                timestamp: new Date(),
                actor: { id: command.workerId, type: 'worker' },
            });

            const activeAssignment = await this.findActiveAssignmentTransactional(manager, task.id);
            if (activeAssignment) {
                activeAssignment.submittedAt = new Date();
                activeAssignment.status = TaskAssignmentStatus.SUBMITTED;
                await manager.save(activeAssignment);
            }

            task.status = TaskStatus.UNDER_REVIEW;
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
            if (task.status === TaskStatus.ACTIVE && !task.assignedTo) return task;

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

            // Return unit to ACTIVE pool so another worker can complete the order
            this.stateMachine.validateTransition({
                taskId: task.id,
                orderId: task.orderId,
                campaignId: task.campaignId,
                taskType: task.taskType,
                currentStatus: TaskStatus.REJECTED,
                targetStatus: TaskStatus.ACTIVE,
                timestamp: new Date(),
                actor: { id: command.reviewedBy || 'system', type: 'system' },
            });

            task.status = TaskStatus.ACTIVE;
            task.assignedTo = null;
            task.assignedAt = null;
            task.acceptedAt = null;
            task.submittedAt = null;
            task.deadline = null;
            task.metadata = {
                ...(task.metadata || {}),
                lastReviewedBy: command.reviewedBy,
                lastReviewNotes: command.notes,
                lastRejectedAt: new Date(),
            };
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

            if (task.assignedTo) {
                const campaignId = task.campaignId || task.orderId;
                await manager.delete(CampaignWorkerParticipation, { campaignId, workerId: task.assignedTo }).catch(() => null);
                task.assignedTo = null;
            }

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
