import { Injectable } from '@nestjs/common';
import { TaskRepository } from '../../shared/database/repositories/task.repository';
import { CampaignWorkerParticipationRepository } from '../../shared/database/repositories/campaign-worker-participation.repository';
import { Task } from '../../shared/database/entities/task.entity';

@Injectable()
export class TaskQueryService {
    constructor(
        private readonly taskRepository: TaskRepository,
        private readonly participationRepo: CampaignWorkerParticipationRepository,
    ) {}

    async getTaskById(taskId: string): Promise<Task | null> {
        return this.taskRepository.findById(taskId);
    }

    async getAvailableTasks(workerId: string, limit: number = 50, offset: number = 0): Promise<Task[]> {
        const availableTasks = await this.taskRepository.findAvailableForAssignment(limit, offset);
        const excludedCampaignIds = new Set(await this.participationRepo.findCampaignIdsByWorker(workerId));

        return availableTasks.filter((task) => !excludedCampaignIds.has(task.campaignId || task.orderId));
    }

    async getWorkerTasks(workerId: string, status?: string): Promise<Task[]> {
        if (status) {
            return this.taskRepository.findByWorkerAndStatus(workerId, status);
        }

        return this.taskRepository.findByWorker(workerId);
    }
}
