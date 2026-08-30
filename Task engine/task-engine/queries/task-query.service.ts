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

    async getAvailableTasks(workerId: string): Promise<Task[]> {
        // 1. Fetch all active unassigned tasks
        const availableTasks = await this.taskRepository.findAvailableForAssignment();

        // 2. Identify campaigns the worker has already participated in (via participations table OR assigned/submitted tasks)
        const excludedCampaignIds = new Set<string>();
        try {
            const participations = await this.participationRepo.findCampaignIdsByWorker(workerId);
            for (const cId of participations) {
                if (cId) excludedCampaignIds.add(cId.toString());
            }
        } catch (_) {}

        try {
            const workerTasks = await this.taskRepository.findByWorker(workerId);
            for (const wt of workerTasks) {
                const cId = wt.campaignId || wt.orderId;
                if (cId) excludedCampaignIds.add(cId.toString());
            }
        } catch (_) {}

        // 3. Filter out campaigns already taken by this worker
        const eligibleTasks = availableTasks.filter((task) => {
            const campaignKey = (task.campaignId || task.orderId || '').toString();
            if (campaignKey && excludedCampaignIds.has(campaignKey)) {
                return false;
            }
            return true;
        });

        // 4. DISTINCT BY CAMPAIGN/ORDER: Exactly 1 task per campaign is offered to each worker
        const seenCampaigns = new Set<string>();
        const distinctTasks: Task[] = [];

        for (const task of eligibleTasks) {
            const campaignKey = (task.campaignId || task.orderId || task.id).toString();
            if (!seenCampaigns.has(campaignKey)) {
                seenCampaigns.add(campaignKey);
                distinctTasks.push(task);
            }
        }

        return distinctTasks;
    }

    async getWorkerTasks(workerId: string, status?: string): Promise<Task[]> {
        if (status) {
            return this.taskRepository.findByWorkerAndStatus(workerId, status);
        }

        return this.taskRepository.findByWorker(workerId);
    }
}
