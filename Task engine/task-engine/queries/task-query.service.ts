import { Injectable } from '@nestjs/common';
import { TaskRepository } from '../../shared/database/repositories/task.repository';
import { CampaignWorkerParticipationRepository } from '../../shared/database/repositories/campaign-worker-participation.repository';
import { SubmissionRepository } from '../../shared/database/repositories/submission.repository';
import { TaskAssignmentRepository } from '../../shared/database/repositories/task-assignment.repository';
import { UserRepository } from '../../shared/database/repositories/user.repository';
import { Task } from '../../shared/database/entities/task.entity';
import { extractTaskIdentity } from '../../shared/common/utils/task-identity.util';

@Injectable()
export class TaskQueryService {
    constructor(
        private readonly taskRepository: TaskRepository,
        private readonly participationRepo: CampaignWorkerParticipationRepository,
        private readonly submissionRepo: SubmissionRepository,
        private readonly assignmentRepo: TaskAssignmentRepository,
        private readonly userRepo: UserRepository,
    ) {}

    async getTaskById(taskId: string): Promise<Task | null> {
        return this.taskRepository.findById(taskId);
    }

    private async resolveAllWorkerIdentifiers(workerId: string, workerEmail?: string): Promise<string[]> {
        const ids = new Set<string>();
        let resolvedEmail = (workerEmail || '').toLowerCase().trim();

        if (workerId) {
            ids.add(workerId);
            if (workerId.includes('@')) {
                resolvedEmail = workerId.toLowerCase().trim();
            }
        }

        if (!resolvedEmail && workerId) {
            try {
                const user = await this.userRepo.findById(workerId);
                if (user?.email) {
                    resolvedEmail = user.email.toLowerCase().trim();
                }
            } catch (_) {}
        }

        if (resolvedEmail) {
            ids.add(resolvedEmail);
            try {
                const user = await this.userRepo.findByEmail(resolvedEmail);
                if (user?.id) ids.add(user.id);
            } catch (_) {}
        }

        return Array.from(ids);
    }

    async getAvailableTasks(workerId: string, workerEmail?: string): Promise<Task[]> {
        // 1. Fetch all active unassigned tasks
        const availableTasks = await this.taskRepository.findAvailableForAssignment();

        // 2. Identify all worker identifiers (Gmail, UID, Worker profile ID)
        const allWorkerIds = await this.resolveAllWorkerIdentifiers(workerId, workerEmail);

        // 3. Collect all campaignIds, taskIds, orderUnitIds, AND workerExcludedPackageIds & workerExcludedUrls
        const excludedCampaignIds = new Set<string>();
        const excludedTaskIds = new Set<string>();
        const excludedOrderUnitIds = new Set<string>();
        const workerExcludedPackageIds = new Set<string>();
        const workerExcludedUrls = new Set<string>();

        const pastTasksMap = new Map<string, Task>();

        // (a) From campaign_worker_participation
        try {
            const participations = await this.participationRepo.findCampaignIdsByWorker(allWorkerIds);
            for (const cId of participations) {
                if (cId) excludedCampaignIds.add(cId.toString());
            }
        } catch (_) {}

        // (b) From task_assignments
        try {
            const assignments = await this.assignmentRepo.findByWorker(allWorkerIds);
            for (const a of assignments) {
                if (a.campaignId) excludedCampaignIds.add(a.campaignId.toString());
                if (a.orderId) excludedCampaignIds.add(a.orderId.toString());
                if (a.taskId) excludedTaskIds.add(a.taskId.toString());
                if (a.orderUnitId) excludedOrderUnitIds.add(a.orderUnitId.toString());
            }
        } catch (_) {}

        // (c) From tasks table where assigned_to in allWorkerIds
        try {
            const workerTasks = await this.taskRepository.findByWorker(allWorkerIds);
            for (const wt of workerTasks) {
                if (wt.campaignId) excludedCampaignIds.add(wt.campaignId.toString());
                if (wt.orderId) excludedCampaignIds.add(wt.orderId.toString());
                if (wt.id) {
                    excludedTaskIds.add(wt.id.toString());
                    pastTasksMap.set(wt.id.toString(), wt);
                }
                if (wt.orderUnitId) excludedOrderUnitIds.add(wt.orderUnitId.toString());
            }
        } catch (_) {}

        // (d) From submissions table (batch fetched to prevent N+1 query overhead)
        try {
            const subs = await this.submissionRepo.findByWorker(allWorkerIds);
            for (const s of subs) {
                if (s.taskId) {
                    excludedTaskIds.add(s.taskId.toString());
                }
            }

            const subTaskIds = Array.from(new Set(subs.map((s) => s.taskId).filter(Boolean))) as string[];
            const missingSubTaskIds = subTaskIds.filter((id) => !pastTasksMap.has(id));
            if (missingSubTaskIds.length > 0) {
                const subTasks = await this.taskRepository.findByIds(missingSubTaskIds);
                for (const t of subTasks) {
                    if (t?.id) pastTasksMap.set(t.id.toString(), t);
                    if (t?.campaignId) excludedCampaignIds.add(t.campaignId.toString());
                    if (t?.orderId) excludedCampaignIds.add(t.orderId.toString());
                    if (t?.orderUnitId) excludedOrderUnitIds.add(t.orderUnitId.toString());
                }
            }
        } catch (_) {}

        // (e) Extract packageId and normalizedUrl from ALL past tasks worker interacted with
        for (const pt of pastTasksMap.values()) {
            const identity = extractTaskIdentity(pt);
            if (identity.packageId) {
                workerExcludedPackageIds.add(identity.packageId);
            }
            if (identity.normalizedUrl) {
                workerExcludedUrls.add(identity.normalizedUrl);
            }
        }

        // 4. Filter out any task matching excluded campaign, order, unit, taskId, OR same App/URL
        const eligibleTasks = availableTasks.filter((task) => {
            const taskCampaign = (task.campaignId || '').toString();
            const taskOrder = (task.orderId || '').toString();
            const taskUnit = (task.orderUnitId || '').toString();
            const taskId = (task.id || '').toString();

            if (taskCampaign && excludedCampaignIds.has(taskCampaign)) return false;
            if (taskOrder && excludedCampaignIds.has(taskOrder)) return false;
            if (taskUnit && excludedOrderUnitIds.has(taskUnit)) return false;
            if (taskId && excludedTaskIds.has(taskId)) return false;

            // 🔒 STRICT BUSINESS RULE:
            // "agar user na same app ka task kia hai toh usko woh task na mila samjha ,
            // aur youtube link instagram , ka url map url bhi same hai alaready kar chuka hai toh task na mila"
            const identity = extractTaskIdentity(task);
            if (identity.packageId && workerExcludedPackageIds.has(identity.packageId)) {
                return false;
            }
            if (identity.normalizedUrl && workerExcludedUrls.has(identity.normalizedUrl)) {
                return false;
            }

            return true;
        });

        // 5. DISTINCT BY CAMPAIGN/ORDER, PACKAGE ID, AND NORMALIZED URL:
        // Exactly 1 task per campaign/order, per app package, and per URL is offered to each worker
        const seenCampaigns = new Set<string>();
        const seenPackageIds = new Set<string>();
        const seenUrls = new Set<string>();
        const distinctTasks: Task[] = [];

        for (const task of eligibleTasks) {
            const campaignKey = (task.campaignId || task.orderId || task.id || '').toString();
            if (campaignKey && seenCampaigns.has(campaignKey)) continue;

            const identity = extractTaskIdentity(task);
            if (identity.packageId && seenPackageIds.has(identity.packageId)) continue;
            if (identity.normalizedUrl && seenUrls.has(identity.normalizedUrl)) continue;

            if (campaignKey) seenCampaigns.add(campaignKey);
            if (identity.packageId) seenPackageIds.add(identity.packageId);
            if (identity.normalizedUrl) seenUrls.add(identity.normalizedUrl);

            distinctTasks.push(task);
        }

        // Guarantee newest tasks are always at the top
        distinctTasks.sort((a, b) => {
            const timeA = a.createdAt ? new Date(a.createdAt).getTime() : 0;
            const timeB = b.createdAt ? new Date(b.createdAt).getTime() : 0;
            return timeB - timeA;
        });

        return distinctTasks;
    }

    /**
     * Resolves all packageIds and normalizedUrls a worker has ever interacted with.
     * Used by Notification Engine to suppress notifications for already completed apps and links.
     */
    async getWorkerExcludedEntities(workerId: string, workerEmail?: string): Promise<{ packageIds: Set<string>; normalizedUrls: Set<string> }> {
        const allWorkerIds = await this.resolveAllWorkerIdentifiers(workerId, workerEmail);
        const packageIds = new Set<string>();
        const normalizedUrls = new Set<string>();
        const pastTasksMap = new Map<string, Task>();

        try {
            const workerTasks = await this.taskRepository.findByWorker(allWorkerIds);
            for (const wt of workerTasks) {
                if (wt.id) pastTasksMap.set(wt.id, wt);
            }
        } catch (_) {}

        try {
            const subs = await this.submissionRepo.findByWorker(allWorkerIds);
            const subTaskIds = Array.from(new Set(subs.map((s) => s.taskId).filter(Boolean))) as string[];
            const missing = subTaskIds.filter((id) => !pastTasksMap.has(id));
            if (missing.length > 0) {
                const subTasks = await this.taskRepository.findByIds(missing);
                for (const t of subTasks) {
                    if (t?.id) pastTasksMap.set(t.id, t);
                }
            }
        } catch (_) {}

        for (const t of pastTasksMap.values()) {
            const identity = extractTaskIdentity(t);
            if (identity.packageId) packageIds.add(identity.packageId);
            if (identity.normalizedUrl) normalizedUrls.add(identity.normalizedUrl);
        }

        return { packageIds, normalizedUrls };
    }

    async getWorkerTasks(workerId: string, status?: string, workerEmail?: string): Promise<Task[]> {
        const allWorkerIds = await this.resolveAllWorkerIdentifiers(workerId, workerEmail);
        let tasks: Task[];
        if (status) {
            tasks = await this.taskRepository.findByWorkerAndStatus(allWorkerIds, status);
        } else {
            tasks = await this.taskRepository.findByWorker(allWorkerIds);
        }

        // Guarantee newest tasks appear on top
        return tasks.sort((a, b) => {
            const timeA = (a.updatedAt || a.createdAt) ? new Date(a.updatedAt || a.createdAt).getTime() : 0;
            const timeB = (b.updatedAt || b.createdAt) ? new Date(b.updatedAt || b.createdAt).getTime() : 0;
            return timeB - timeA;
        });
    }
}
