import { Injectable } from '@nestjs/common';
import { TaskRepository } from '../../shared/database/repositories/task.repository';
import { CampaignWorkerParticipationRepository } from '../../shared/database/repositories/campaign-worker-participation.repository';
import { SubmissionRepository } from '../../shared/database/repositories/submission.repository';
import { TaskAssignmentRepository } from '../../shared/database/repositories/task-assignment.repository';
import { UserRepository } from '../../shared/database/repositories/user.repository';
import { Task } from '../../shared/database/entities/task.entity';

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

    private extractTaskIdentity(task: any): { packageId?: string; normalizedUrl?: string } {
        const reqs = task?.requirements || {};
        const meta = task?.metadata || {};
        const pkg = (reqs.packageId || meta.packageId || '').toString().trim().toLowerCase();
        let rawUrl = (reqs.targetUrl || meta.targetUrl || '').toString().trim().toLowerCase();
        let normalizedUrl = '';
        if (rawUrl) {
            try {
                const parsed = new URL(rawUrl);
                // Strip common tracking and referrer params
                ['utm_source', 'utm_medium', 'utm_campaign', 'utm_term', 'utm_content', 'si', 'fbclid', 'igsh', 'feature', 'ref', 'source'].forEach((p) => {
                    parsed.searchParams.delete(p);
                });

                if (parsed.hostname.includes('google.com') && parsed.pathname.includes('/store/apps/details')) {
                    // Google Play app listings must be distinct by app package id
                    const idParam = (parsed.searchParams.get('id') || pkg || '').toLowerCase().trim();
                    normalizedUrl = idParam ? `${parsed.origin}${parsed.pathname}?id=${idParam}` : `${parsed.origin}${parsed.pathname}`;
                } else if (parsed.hostname.includes('youtube.com') && parsed.pathname.includes('/watch')) {
                    // YouTube video watch URLs must be distinct by video id
                    const vParam = (parsed.searchParams.get('v') || '').trim();
                    normalizedUrl = vParam ? `${parsed.origin}${parsed.pathname}?v=${vParam}` : `${parsed.origin}${parsed.pathname}`;
                } else if (parsed.hostname.includes('youtu.be')) {
                    // Short YouTube video links: youtu.be/<id>
                    normalizedUrl = `${parsed.origin}${parsed.pathname}`.replace(/\/+$/, '');
                } else {
                    // Other URLs (e.g. Google Maps, websites, Instagram posts)
                    const cleanSearch = parsed.searchParams.toString();
                    normalizedUrl = cleanSearch
                        ? `${parsed.origin}${parsed.pathname.replace(/\/+$/, '')}?${cleanSearch}`
                        : `${parsed.origin}${parsed.pathname}`.replace(/\/+$/, '');
                }
            } catch (_) {
                normalizedUrl = rawUrl.replace(/\/+$/, '');
            }
        }
        return {
            packageId: pkg || undefined,
            normalizedUrl: normalizedUrl || undefined,
        };
    }

    async getAvailableTasks(workerId: string, workerEmail?: string): Promise<Task[]> {
        // 1. Fetch all active unassigned tasks
        const availableTasks = await this.taskRepository.findAvailableForAssignment();

        // 2. Identify all worker identifiers (Gmail, UID, Worker profile ID)
        const allWorkerIds = await this.resolveAllWorkerIdentifiers(workerId, workerEmail);

        // 3. Collect all campaignIds, taskIds, orderUnitIds, packageIds, and targetUrls the worker has ever interacted with
        const excludedCampaignIds = new Set<string>();
        const excludedTaskIds = new Set<string>();
        const excludedOrderUnitIds = new Set<string>();
        const excludedPackageIds = new Set<string>();
        const excludedTargetUrls = new Set<string>();

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
                if (wt.id) excludedTaskIds.add(wt.id.toString());
                if (wt.orderUnitId) excludedOrderUnitIds.add(wt.orderUnitId.toString());
                const { packageId, normalizedUrl } = this.extractTaskIdentity(wt);
                if (packageId) excludedPackageIds.add(packageId);
                if (normalizedUrl) excludedTargetUrls.add(normalizedUrl);
            }
        } catch (_) {}

        // (d) From submissions table (batch fetched to prevent N+1 query overhead)
        try {
            const subs = await this.submissionRepo.findByWorker(allWorkerIds);
            const subTaskIds = Array.from(new Set(subs.map((s) => s.taskId).filter(Boolean)));
            for (const sId of subTaskIds) {
                excludedTaskIds.add(sId.toString());
            }

            if (subTaskIds.length > 0) {
                const subTasks = await this.taskRepository.findByIds(subTaskIds);
                for (const t of subTasks) {
                    if (t?.campaignId) excludedCampaignIds.add(t.campaignId.toString());
                    if (t?.orderId) excludedCampaignIds.add(t.orderId.toString());
                    if (t?.orderUnitId) excludedOrderUnitIds.add(t.orderUnitId.toString());
                    const { packageId, normalizedUrl } = this.extractTaskIdentity(t);
                    if (packageId) excludedPackageIds.add(packageId);
                    if (normalizedUrl) excludedTargetUrls.add(normalizedUrl);
                }
            }
        } catch (_) {}

        // 4. Filter out any task matching excluded campaign, order, unit, taskId, packageId, or targetUrl
        const eligibleTasks = availableTasks.filter((task) => {
            const taskCampaign = (task.campaignId || '').toString();
            const taskOrder = (task.orderId || '').toString();
            const taskUnit = (task.orderUnitId || '').toString();
            const taskId = (task.id || '').toString();
            const { packageId, normalizedUrl } = this.extractTaskIdentity(task);

            if (taskCampaign && excludedCampaignIds.has(taskCampaign)) return false;
            if (taskOrder && excludedCampaignIds.has(taskOrder)) return false;
            if (taskUnit && excludedOrderUnitIds.has(taskUnit)) return false;
            if (taskId && excludedTaskIds.has(taskId)) return false;
            if (packageId && excludedPackageIds.has(packageId)) return false;
            if (normalizedUrl && excludedTargetUrls.has(normalizedUrl)) return false;

            return true;
        });

        // 5. DISTINCT BY CAMPAIGN/ORDER & TARGET APP/URL: Exactly 1 task/unit per campaign is offered to each worker
        const seenCampaigns = new Set<string>();
        const seenPackages = new Set<string>();
        const seenUrls = new Set<string>();
        const distinctTasks: Task[] = [];

        for (const task of eligibleTasks) {
            const campaignKey = (task.campaignId || task.orderId || task.id || '').toString();
            const { packageId, normalizedUrl } = this.extractTaskIdentity(task);

            if (seenCampaigns.has(campaignKey)) continue;
            if (packageId && seenPackages.has(packageId)) continue;
            if (normalizedUrl && seenUrls.has(normalizedUrl)) continue;

            seenCampaigns.add(campaignKey);
            if (packageId) seenPackages.add(packageId);
            if (normalizedUrl) seenUrls.add(normalizedUrl);

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
