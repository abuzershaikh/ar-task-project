import { DataSource, In } from 'typeorm';
import { Task } from '../../../database/entities/task.entity';
import { TaskAssignment } from '../../../database/entities/task-assignment.entity';
import { CampaignWorkerParticipation } from '../../../database/entities/campaign-worker-participation.entity';
import { executionDeadline } from '../../../common/utils/worker-execution-deadline';
import { ReleaseReason } from '../types/reallocation.types';
import { Injectable, Logger } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { TaskRepository } from '../../../database/repositories/task.repository';
import { CampaignWorkerParticipationRepository } from '../../../database/repositories/campaign-worker-participation.repository';
import { TaskAssignmentRepository } from '../../../database/repositories/task-assignment.repository';
import { ParticipationStatus } from '../../../database/entities/campaign-worker-participation.entity';
import { TaskAssignmentStatus } from '../../../database/entities/task-assignment.entity';
import { TaskStatus } from '../../../../task-engine/types/task-status.enum';
import { TaskReleaseRequest } from '../types/reallocation.types';

@Injectable()
export class TaskReleaseService {
    private readonly logger = new Logger(TaskReleaseService.name);

    constructor(
        private readonly taskRepo: TaskRepository,
        private readonly participationRepo: CampaignWorkerParticipationRepository,
        private readonly assignmentRepo: TaskAssignmentRepository,
        private readonly eventEmitter: EventEmitter2,
        private readonly dataSource: DataSource,
    ) { }

    async releaseWorkerFromTask(request: TaskReleaseRequest): Promise<boolean> {
        const released = await this.dataSource.transaction(async (manager) => {
            // The same row lock used by acceptance and proof submission serializes all three paths.
            const task = await manager.findOne(Task, {
                where: { id: request.taskId }, lock: { mode: 'pessimistic_write' },
            });
            if (!task || task.assignedTo !== request.workerId || task.submittedAt) return false;
            if (!['assigned', 'accepted', 'in_progress'].includes(task.status.toLowerCase())) return false;
            if (request.reason === ReleaseReason.WORKER_TIMEOUT) {
                const deadline = executionDeadline(task) || request.expectedDeadline;
                if (!deadline || new Date(deadline).getTime() > Date.now()) return false;
            }

            const campaignId = task.campaignId || task.orderId;
            let participation = await manager.findOne(CampaignWorkerParticipation, {
                where: { campaignId, workerId: request.workerId },
            });
            if (!participation) {
                participation = manager.create(CampaignWorkerParticipation, {
                    campaignId, workerId: request.workerId, expiredCount: 0,
                });
            }
            participation.status = ParticipationStatus.EXPIRED;
            participation.expiredCount = Number(participation.expiredCount || 0) + 1;
            participation.lastAssignedAt = new Date();
            await manager.save(participation);

            const assignment = await manager.findOne(TaskAssignment, {
                where: { taskId: task.id, workerId: request.workerId,
                    status: In([TaskAssignmentStatus.ASSIGNED, TaskAssignmentStatus.ACCEPTED, TaskAssignmentStatus.STARTED]) },
                order: { attemptNumber: 'DESC' },
            });
            if (assignment) {
                assignment.status = request.reason === ReleaseReason.WORKER_TIMEOUT
                    ? TaskAssignmentStatus.EXPIRED : TaskAssignmentStatus.EARLY_RELEASED;
                assignment.expiredAt = new Date();
                assignment.releaseReason = request.reason;
                await manager.save(assignment);
            }

            // Keep task/order-unit identity and historical attempts so the previous worker stays excluded.
            task.assignedTo = null;
            task.assignedAt = null;
            task.acceptedAt = null;
            task.startedAt = null;
            task.deadline = null;
            task.status = TaskStatus.ACTIVE;
            const metadata = { ...(task.metadata || {}) };
            delete metadata.executionStartedAt;
            task.metadata = metadata;
            await manager.save(task);
            return true;
        });
        if (released) {
            this.eventEmitter.emit('worker.task_released', {
                workerId: request.workerId, taskId: request.taskId, campaignId: request.campaignId,
                reason: request.reason, timestamp: new Date(),
            });
        }
        return released;
    }
}
