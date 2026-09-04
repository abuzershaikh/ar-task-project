import { Injectable } from '@nestjs/common';
import { TaskRepository } from '../../shared/database/repositories/task.repository';
import { CampaignWorkerParticipationRepository } from '../../shared/database/repositories/campaign-worker-participation.repository';
import { SubmissionRepository } from '../../shared/database/repositories/submission.repository';
import { UserRepository } from '../../shared/database/repositories/user.repository';
import { Task } from '../../shared/database/entities/task.entity';

@Injectable()
export class TaskQueryService {
    constructor(
        private readonly taskRepository: TaskRepository,
        private readonly participationRepo: CampaignWorkerParticipationRepository,
        private readonly submissionRepo: SubmissionRepository,
        private readonly userRepo: UserRepository,
    ) {}

    async getTaskById(taskId: string): Promise<Task | null> {
        return this.taskRepository.findById(taskId);
    }

    async getAvailableTasks(workerId: string): Promise<Task[]> {
        // 1. Fetch all active unassigned tasks
        const availableTasks = await this.taskRepository.findAvailableForAssignment();

        // 2. Identify all worker identifiers (ID, Email, Firebase UID)
        const workerIds = new Set<string>();
        if (workerId) workerIds.add(workerId.toString());

        try {
            const user = await this.userRepo.findById(workerId);
            if (user) {
                if (user.id) workerIds.add(user.id);
                if (user.email) workerIds.add(user.email);
            } else {
                const userByEmail = await this.userRepo.findByEmail(workerId);
                if (userByEmail) {
                    if (userByEmail.id) workerIds.add(userByEmail.id);
                    if (userByEmail.email) workerIds.add(userByEmail.email);
                }
            }
        } catch (_) {}

        // 3. Identify campaigns the worker has already participated in
        const excludedCampaignIds = new Set<string>();

        for (const wId of workerIds) {
            try {
                const participations = await this.participationRepo.findCampaignIdsByWorker(wId);
                for (const cId of participations) {
                    if (cId) excludedCampaignIds.add(cId.toString());
                }
            } catch (_) {}

            try {
                const workerTasks = await this.taskRepository.findByWorker(wId);
                for (const wt of workerTasks) {
                    const cId = wt.campaignId || wt.orderId;
                    if (cId) excludedCampaignIds.add(cId.toString());
                }
            } catch (_) {}

            try {
                const subs = await this.submissionRepo.findByWorker(wId);
                for (const s of subs) {
                    if (s.taskId) {
                        const t = await this.taskRepository.findById(s.taskId);
                        const cId = t?.campaignId || t?.orderId;
                        if (cId) excludedCampaignIds.add(cId.toString());
                    }
                }
            } catch (_) {}
        }

        // 4. Filter out campaigns already taken by this worker
        const eligibleTasks = availableTasks.filter((task) => {
            const campaignKey = (task.campaignId || task.orderId || '').toString();
            if (campaignKey && excludedCampaignIds.has(campaignKey)) {
                return false;
            }
            return true;
        });

        // 5. DISTINCT BY CAMPAIGN/ORDER: Exactly 1 task per campaign is offered to each worker
        const seenCampaigns = new Set<string>();
        const distinctTasks: Task[] = [];

        for (const task of eligibleTasks) {
            const campaignKey = (task.campaignId || task.orderId || task.id).toString();
            if (!seenCampaigns.has(campaignKey)) {
                seenCampaigns.add(campaignKey);
                distinctTasks.push(task);
            }
        }

        // Guarantee newest tasks are always at the top
        distinctTasks.sort((a, b) => {
            const timeA = a.createdAt ? new Date(a.createdAt).getTime() : 0;
            const timeB = b.createdAt ? new Date(b.createdAt).getTime() : 0;
            return timeB - timeA;
        });

        return distinctTasks;
    }

    async getWorkerTasks(workerId: string, status?: string): Promise<Task[]> {
        let tasks: Task[];
        if (status) {
            tasks = await this.taskRepository.findByWorkerAndStatus(workerId, status);
        } else {
            tasks = await this.taskRepository.findByWorker(workerId);
        }

        // Guarantee newest tasks appear on top
        return tasks.sort((a, b) => {
            const timeA = (a.updatedAt || a.createdAt) ? new Date(a.updatedAt || a.createdAt).getTime() : 0;
            const timeB = (b.updatedAt || b.createdAt) ? new Date(b.updatedAt || b.createdAt).getTime() : 0;
            return timeB - timeA;
        });
    }
}
