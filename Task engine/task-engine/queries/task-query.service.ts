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

        try {
            const rows = await this.taskRepository.query(
                `SELECT u.id AS userId, u.email AS userEmail, w.id AS workerId
                 FROM users u
                 LEFT JOIN workers w ON w.user_id = u.id
                 WHERE u.id = ? OR u.email = ? OR w.id = ? OR w.user_id = ?`,
                [workerId, resolvedEmail || workerId, workerId, workerId],
            );
            for (const r of rows) {
                if (r.userId) ids.add(r.userId.toString().trim());
                if (r.userEmail) ids.add(r.userEmail.toString().trim().toLowerCase());
                if (r.workerId) ids.add(r.workerId.toString().trim());
            }
        } catch (_) {}

        if (!resolvedEmail && workerId) {
            try {
                const user = await this.userRepo.findById(workerId);
                if (user?.email) {
                    resolvedEmail = user.email.toLowerCase().trim();
                    ids.add(resolvedEmail);
                }
            } catch (_) {}
        }

        return Array.from(ids);
    }

    async getAvailableTasks(workerId: string, workerEmail?: string): Promise<Task[]> {
        // 1. Fetch all active unassigned tasks
        const availableTasks = await this.taskRepository.findAvailableForAssignment();

        // 2. Identify all worker identifiers (Gmail, UID, Worker profile ID)
        const allWorkerIds = await this.resolveAllWorkerIdentifiers(workerId, workerEmail);

        // 3. Collect all campaignIds, taskIds, orderUnitIds, AND workerExcludedPackageIds & workerExcludedUrls & entityKeys
        const excludedCampaignIds = new Set<string>();
        const excludedTaskIds = new Set<string>();
        const excludedOrderUnitIds = new Set<string>();
        const workerExcludedPackageIds = new Set<string>();
        const workerExcludedUrls = new Set<string>();
        const workerExcludedBusinessNames = new Set<string>();
        const workerExcludedEntityKeys = new Set<string>();

        const pastTasksMap = new Map<string, Task>();

        // (0) Fetch directly from worker_completed_identities table (physical DB records)
        if (allWorkerIds.length > 0) {
            try {
                const identityRows = await this.taskRepository.query(
                    `SELECT entity_key FROM worker_completed_identities WHERE worker_key IN (?)`,
                    [allWorkerIds.map((id) => id.toLowerCase().trim())],
                );
                for (const row of identityRows) {
                    if (row.entity_key) {
                        const key = row.entity_key.toString().toLowerCase().trim();
                        workerExcludedEntityKeys.add(key);
                        if (key.startsWith('pkg:')) {
                            workerExcludedPackageIds.add(key.replace('pkg:', ''));
                        } else if (key.startsWith('url:')) {
                            workerExcludedUrls.add(key.replace('url:', ''));
                        } else if (key.startsWith('gmb:name:')) {
                            workerExcludedBusinessNames.add(key);
                        }
                    }
                }
            } catch (_) {}
        }

        // (a) From campaign_worker_participation
        try {
            const participations = await this.participationRepo.findCampaignIdsByWorker(allWorkerIds);
            for (const cId of participations) {
                if (cId) excludedCampaignIds.add(cId.toString());
            }
        } catch (_) {}

        // (b) From task_assignments (all historical attempts: expired, released, completed)
        try {
            const assignments = await this.assignmentRepo.findByWorker(allWorkerIds);
            const assignmentTaskIds: string[] = [];
            for (const a of assignments) {
                if (a.campaignId) excludedCampaignIds.add(a.campaignId.toString());
                if (a.orderId) excludedCampaignIds.add(a.orderId.toString());
                if (a.taskId) {
                    excludedTaskIds.add(a.taskId.toString());
                    assignmentTaskIds.push(a.taskId.toString());
                }
                if (a.orderUnitId) excludedOrderUnitIds.add(a.orderUnitId.toString());
            }

            const missingAssignmentTaskIds = Array.from(new Set(assignmentTaskIds)).filter((id) => !pastTasksMap.has(id));
            if (missingAssignmentTaskIds.length > 0) {
                const assignedTasks = await this.taskRepository.findByIds(missingAssignmentTaskIds);
                for (const t of assignedTasks) {
                    if (t?.id) pastTasksMap.set(t.id.toString(), t);
                }
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

        // (e) Extract packageId, normalizedUrl, businessNameKey, and entityKeys from ALL past tasks worker interacted with
        for (const pt of pastTasksMap.values()) {
            const identity = extractTaskIdentity(pt);
            if (identity.packageId) {
                workerExcludedPackageIds.add(identity.packageId.toLowerCase().trim());
            }
            if (identity.normalizedUrl) {
                workerExcludedUrls.add(identity.normalizedUrl.toLowerCase().trim());
            }
            if (identity.businessNameKey) {
                workerExcludedBusinessNames.add(identity.businessNameKey.toLowerCase().trim());
            }
            if (identity.entityKeys && identity.entityKeys.length > 0) {
                for (const k of identity.entityKeys) {
                    workerExcludedEntityKeys.add(k.toLowerCase().trim());
                }
            } else if (identity.entityKey) {
                workerExcludedEntityKeys.add(identity.entityKey.toLowerCase().trim());
            }
        }

        // 4. Filter out any task matching excluded campaign, order, unit, taskId, OR same App/Business/URL
        const eligibleTasks = availableTasks.filter((task) => {
            const taskCampaign = (task.campaignId || '').toString();
            const taskOrder = (task.orderId || '').toString();
            const taskUnit = (task.orderUnitId || '').toString();
            const taskId = (task.id || '').toString();

            if (taskCampaign && excludedCampaignIds.has(taskCampaign)) return false;
            if (taskOrder && excludedCampaignIds.has(taskOrder)) return false;
            if (taskUnit && excludedOrderUnitIds.has(taskUnit)) return false;
            if (taskId && excludedTaskIds.has(taskId)) return false;

            // 🔒 STRICT UNIQUE SYSTEM RULE:
            // "App Reviews & Google Reviews ke Task mei Repeat Users Task karrahe hai Usme Unique System Chahiye,
            // same link aana par repeat user ko task nahi jana chaia"
            const identity = extractTaskIdentity(task);
            if (identity.packageId && workerExcludedPackageIds.has(identity.packageId.toLowerCase().trim())) {
                return false;
            }
            if (identity.normalizedUrl && workerExcludedUrls.has(identity.normalizedUrl.toLowerCase().trim())) {
                return false;
            }
            if (identity.businessNameKey && workerExcludedBusinessNames.has(identity.businessNameKey.toLowerCase().trim())) {
                return false;
            }
            if (identity.entityKeys && identity.entityKeys.length > 0) {
                const hasMatch = identity.entityKeys.some((k) => workerExcludedEntityKeys.has(k.toLowerCase().trim()));
                if (hasMatch) return false;
            } else if (identity.entityKey && workerExcludedEntityKeys.has(identity.entityKey.toLowerCase().trim())) {
                return false;
            }

            return true;
        });

        // 5. DISTINCT BY CAMPAIGN/ORDER, PACKAGE ID, NORMALIZED URL, BUSINESS NAME, AND ENTITY KEYS:
        // Guarantee exactly 1 task per campaign/order, per app package, per business, and per link is offered
        const seenCampaigns = new Set<string>();
        const seenPackageIds = new Set<string>();
        const seenUrls = new Set<string>();
        const seenBusinessNames = new Set<string>();
        const seenEntityKeys = new Set<string>();
        const distinctTasks: Task[] = [];

        for (const task of eligibleTasks) {
            const campaignKey = (task.campaignId || task.orderId || task.id || '').toString();
            if (campaignKey && seenCampaigns.has(campaignKey)) continue;

            const identity = extractTaskIdentity(task);
            if (identity.packageId && seenPackageIds.has(identity.packageId.toLowerCase().trim())) continue;
            if (identity.normalizedUrl && seenUrls.has(identity.normalizedUrl.toLowerCase().trim())) continue;
            if (identity.businessNameKey && seenBusinessNames.has(identity.businessNameKey.toLowerCase().trim())) continue;
            if (identity.entityKeys && identity.entityKeys.some((k) => seenEntityKeys.has(k.toLowerCase().trim()))) continue;

            if (campaignKey) seenCampaigns.add(campaignKey);
            if (identity.packageId) seenPackageIds.add(identity.packageId.toLowerCase().trim());
            if (identity.normalizedUrl) seenUrls.add(identity.normalizedUrl.toLowerCase().trim());
            if (identity.businessNameKey) seenBusinessNames.add(identity.businessNameKey.toLowerCase().trim());
            if (identity.entityKeys) {
                for (const k of identity.entityKeys) {
                    seenEntityKeys.add(k.toLowerCase().trim());
                }
            }

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
     * Resolves all packageIds, normalizedUrls, businessNameKeys, and entityKeys a worker has ever interacted with.
     * Used by Notification Engine to suppress notifications for already completed apps and links.
     */
    async getWorkerExcludedEntities(
        workerId: string,
        workerEmail?: string,
    ): Promise<{
        packageIds: Set<string>;
        normalizedUrls: Set<string>;
        businessNameKeys: Set<string>;
        entityKeys: Set<string>;
    }> {
        const allWorkerIds = await this.resolveAllWorkerIdentifiers(workerId, workerEmail);
        const packageIds = new Set<string>();
        const normalizedUrls = new Set<string>();
        const businessNameKeys = new Set<string>();
        const entityKeys = new Set<string>();
        const pastTasksMap = new Map<string, Task>();

        // (0) Fetch directly from worker_completed_identities table
        if (allWorkerIds.length > 0) {
            try {
                const rows = await this.taskRepository.query(
                    `SELECT entity_key FROM worker_completed_identities WHERE worker_key IN (?)`,
                    [allWorkerIds.map((id) => id.toLowerCase().trim())],
                );
                for (const r of rows) {
                    if (r.entity_key) {
                        const key = r.entity_key.toString().toLowerCase().trim();
                        entityKeys.add(key);
                        if (key.startsWith('pkg:')) packageIds.add(key.replace('pkg:', ''));
                        else if (key.startsWith('url:')) normalizedUrls.add(key.replace('url:', ''));
                        else if (key.startsWith('gmb:name:')) businessNameKeys.add(key);
                    }
                }
            } catch (_) {}
        }

        try {
            const workerTasks = await this.taskRepository.findByWorker(allWorkerIds);
            for (const wt of workerTasks) {
                if (wt.id) pastTasksMap.set(wt.id, wt);
            }
        } catch (_) {}

        // Include all historical task_assignments (covers expired, released, rejected, completed)
        try {
            const assignments = await this.assignmentRepo.findByWorker(allWorkerIds);
            const assignmentTaskIds = Array.from(new Set(assignments.map((a) => a.taskId).filter(Boolean))) as string[];
            const missing = assignmentTaskIds.filter((id) => !pastTasksMap.has(id));
            if (missing.length > 0) {
                const assignTasks = await this.taskRepository.findByIds(missing);
                for (const t of assignTasks) {
                    if (t?.id) pastTasksMap.set(t.id, t);
                }
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
            if (identity.packageId) packageIds.add(identity.packageId.toLowerCase().trim());
            if (identity.normalizedUrl) normalizedUrls.add(identity.normalizedUrl.toLowerCase().trim());
            if (identity.businessNameKey) businessNameKeys.add(identity.businessNameKey.toLowerCase().trim());
            if (identity.entityKeys && identity.entityKeys.length > 0) {
                for (const k of identity.entityKeys) {
                    entityKeys.add(k.toLowerCase().trim());
                }
            } else if (identity.entityKey) {
                entityKeys.add(identity.entityKey.toLowerCase().trim());
            }
        }

        return { packageIds, normalizedUrls, businessNameKeys, entityKeys };
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
