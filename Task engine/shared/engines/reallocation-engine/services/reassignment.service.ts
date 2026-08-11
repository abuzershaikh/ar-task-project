import { Injectable, Logger } from '@nestjs/common';
import { TaskRepository } from '../../../database/repositories/task.repository';
import { CampaignWorkerParticipationRepository } from '../../../database/repositories/campaign-worker-participation.repository';
import { TaskAssignmentRepository } from '../../../database/repositories/task-assignment.repository';
import { ParticipationStatus } from '../../../database/entities/campaign-worker-participation.entity';
import { MatchingEngineService } from '../../../../matching-engine/matching-engine.service';

@Injectable()
export class ReassignmentService {
    private readonly logger = new Logger(ReassignmentService.name);

    constructor(
        private readonly taskRepo: TaskRepository,
        private readonly participationRepo: CampaignWorkerParticipationRepository,
        private readonly assignmentRepo: TaskAssignmentRepository,
        private readonly matchingEngine: MatchingEngineService,
    ) { }

    async reassignTaskToNewWorker(taskId: string, campaignId: string): Promise<string | null> {
        this.logger.log(`Attempting reassignment for Task '${taskId}' in Campaign '${campaignId}'...`);

        try {
            // Invokes Matching Engine (Matching Engine excludes all workers present in campaign_worker_participation)
            const matchResult = await this.matchingEngine.matchWorkersForTask({ taskId });

            const selectedWorkerId =
                matchResult.matchedWorkers && matchResult.matchedWorkers.length > 0
                    ? matchResult.matchedWorkers[0].workerId
                    : null;

            if (!selectedWorkerId) {
                this.logger.warn(
                    `Reassignment pending for Task '${taskId}': Insufficient eligible unique workers in Campaign '${campaignId}'.`,
                );
                return null;
            }

            // Assign new worker to task
            await this.taskRepo.update(taskId, {
                assignedTo: selectedWorkerId,
                assignedAt: new Date(),
                status: 'assigned',
            });

            // Record Campaign Participation for new worker
            await this.participationRepo.recordParticipation(
                campaignId,
                selectedWorkerId,
                ParticipationStatus.ASSIGNED,
            );

            // Record Task Assignment History
            await this.assignmentRepo.createAssignment({
                taskId,
                campaignId,
                workerId: selectedWorkerId,
            });

            this.logger.log(`Task '${taskId}' successfully REASSIGNED to new unused Worker '${selectedWorkerId}'.`);
            return selectedWorkerId;
        } catch (error) {
            this.logger.error(`Error during task reassignment for Task '${taskId}': ${error.message}`);
            return null;
        }
    }
}
