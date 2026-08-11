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
    ) { }

    async releaseWorkerFromTask(request: TaskReleaseRequest): Promise<boolean> {
        this.logger.warn(
            `Releasing Worker '${request.workerId}' from Task '${request.taskId}' in Campaign '${request.campaignId}'. Reason: ${request.reason}.`,
        );

        // 1. Update Participation Status to EXPIRED (Participation record REMAINS locked in DB for Exclusion!)
        await this.participationRepo.updateStatus(
            request.campaignId,
            request.workerId,
            ParticipationStatus.EXPIRED,
        );

        // 2. Update active TaskAssignment record with releaseReason
        const activeAssignment = await this.assignmentRepo.findActiveAssignment(request.taskId);
        if (activeAssignment) {
            await this.assignmentRepo.updateStatus(
                activeAssignment.id,
                TaskAssignmentStatus.EARLY_RELEASED,
                { expiredAt: new Date(), releaseReason: request.reason },
            );
        }

        // 3. Reset Task entity state to 'active' and unassign worker
        await this.taskRepo.update(request.taskId, {
            assignedTo: null,
            assignedAt: null,
            acceptedAt: null,
            startedAt: null,
            submittedAt: null,
            completedAt: null,
            status: TaskStatus.ACTIVE,
        });

        // 4. Dispatch event for Scoring Engine reliability score penalty
        this.eventEmitter.emit('worker.task_released', {
            workerId: request.workerId,
            taskId: request.taskId,
            campaignId: request.campaignId,
            reason: request.reason,
            timestamp: new Date(),
        });

        return true;
    }
}
