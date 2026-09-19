import { Injectable, Logger } from '@nestjs/common';
import { TaskRepository } from '../../shared/database/repositories/task.repository';
import { CampaignWorkerParticipationRepository } from '../../shared/database/repositories/campaign-worker-participation.repository';
import { MatchingContext } from '../types';
import { extractTaskIdentity } from '../../shared/common/utils/task-identity.util';

/**
 * Duplicate task & Campaign-level worker participation filter.
 * Ensures a worker participates at most ONCE in a single Campaign (campaignId).
 * If a worker's task attempt expired or was rejected in Campaign A, they remain EXCLUDED from Campaign A.
 * Also strictly excludes any worker who has already completed or accepted a task for the same App Package or same URL.
 */
@Injectable()
export class DuplicateFilterService {
    private readonly logger = new Logger(DuplicateFilterService.name);

    constructor(
        private readonly taskRepo: TaskRepository,
        private readonly participationRepo: CampaignWorkerParticipationRepository,
    ) { }

    async apply(
        workerIds: string[],
        context: MatchingContext,
        preloadedUsedWorkerIdsInCampaign?: string[],
        preloadedTaskParticipationMap?: Map<string, boolean>
    ): Promise<string[]> {
        const campaignId = context.task.campaignId || context.task.orderId;
        const orderId = context.task.orderId;

        // 1. Fetch all used worker IDs from CampaignWorkerParticipation DB table
        let usedWorkerIdsInCampaign: string[] = preloadedUsedWorkerIdsInCampaign || [];
        if (!preloadedUsedWorkerIdsInCampaign && campaignId) {
            usedWorkerIdsInCampaign = await this.participationRepo.findUsedWorkerIdsByCampaign(campaignId);
        }

        // 2. Fetch bulk campaign participation map from Task repository
        let taskParticipationMap = preloadedTaskParticipationMap;
        if (!taskParticipationMap) {
            taskParticipationMap = await this.taskRepo.getWorkerCampaignParticipationMap(
                workerIds,
                campaignId,
                orderId,
            );
        }

        // 3. Check Cross-Campaign App Package and Target URL duplication
        const targetIdentity = extractTaskIdentity(context.task);
        const workersWithSameAppOrUrl = new Set<string>();

        if (targetIdentity.packageId || targetIdentity.normalizedUrl) {
            try {
                const excluded = await this.taskRepo.findWorkerIdsWithPackageOrUrl(
                    targetIdentity.packageId,
                    targetIdentity.normalizedUrl,
                );
                for (const id of excluded) {
                    workersWithSameAppOrUrl.add(id.toLowerCase().trim());
                }
            } catch (err) {
                this.logger.error(`Fail-Closed: Error checking cross-campaign task identity: ${err.message}`);
                throw err;
            }
        }

        const eligibleWorkers: string[] = [];

        // 1. Expand usedWorkerIdsInCampaign with ALL aliases (User ID, Worker UUID, Email)
        const usedWorkerSet = new Set<string>();
        for (const id of usedWorkerIdsInCampaign) {
            if (id) usedWorkerSet.add(id.toLowerCase().trim());
        }

        if (usedWorkerIdsInCampaign.length > 0) {
            try {
                const aliasRows = await this.taskRepo.query(
                    `SELECT u.id AS userId, u.email AS userEmail, w.id AS workerId
                     FROM users u
                     LEFT JOIN workers w ON w.user_id = u.id
                     WHERE u.id IN (?) OR u.email IN (?) OR w.id IN (?)`,
                    [usedWorkerIdsInCampaign, usedWorkerIdsInCampaign, usedWorkerIdsInCampaign],
                );
                for (const r of aliasRows) {
                    if (r.userId) usedWorkerSet.add(r.userId.toLowerCase().trim());
                    if (r.userEmail) usedWorkerSet.add(r.userEmail.toLowerCase().trim());
                    if (r.workerId) usedWorkerSet.add(r.workerId.toLowerCase().trim());
                }
            } catch (err: any) {
                this.logger.error(`Fail-Closed: Could not resolve aliases for used campaign workers: ${err?.message}`);
                throw err;
            }
        }

        // 2. Pre-resolve aliases for all candidate workers to guarantee 3-way matching
        const candidateAliasesMap = new Map<string, string[]>();
        if (workerIds.length > 0) {
            try {
                const candRows = await this.taskRepo.query(
                    `SELECT u.id AS userId, u.email AS userEmail, w.id AS workerId
                     FROM workers w
                     LEFT JOIN users u ON u.id = w.user_id
                     WHERE w.id IN (?) OR u.id IN (?) OR u.email IN (?)`,
                    [workerIds, workerIds, workerIds],
                );
                for (const r of candRows) {
                    const aliases = [r.userId, r.userEmail, r.workerId].filter(Boolean).map((s: string) => s.toLowerCase().trim());
                    if (r.workerId) candidateAliasesMap.set(r.workerId.toLowerCase().trim(), aliases);
                    if (r.userId) candidateAliasesMap.set(r.userId.toLowerCase().trim(), aliases);
                    if (r.userEmail) candidateAliasesMap.set(r.userEmail.toLowerCase().trim(), aliases);
                }
            } catch (err: any) {
                this.logger.error(`Fail-Closed: Could not resolve candidate worker aliases: ${err?.message}`);
                throw err;
            }
        }

        // 3. Apply strict 3-way exclusion rules across candidate aliases
        for (const workerId of workerIds) {
            const normalizedWId = (workerId || '').toLowerCase().trim();
            const workerAliases = candidateAliasesMap.get(normalizedWId) || [normalizedWId];

            // Strict Exclusion Rule 1: Worker has ALREADY participated in Campaign (checked across worker UUID, user auth ID, and email)
            const hasParticipatedInCampaign = campaignId && workerAliases.some((alias) => usedWorkerSet.has(alias));
            if (hasParticipatedInCampaign) {
                this.logger.debug(`Worker '${workerId}' EXCLUDED from Campaign '${campaignId}' (Already participated/expired across aliases)`);
                continue;
            }

            // Strict Exclusion Rule 2: Check active task assignments in Task table via bulk map
            const hasActiveOrCompletedInCampaign = taskParticipationMap.get(workerId) === true || workerAliases.some((alias) => taskParticipationMap.get(alias) === true);
            if (hasActiveOrCompletedInCampaign) {
                continue;
            }

            // Strict Exclusion Rule 3: Same app package or same target URL completed (checked across all aliases)
            const hasCompletedSameAppOrUrl = workerAliases.some((alias) => workersWithSameAppOrUrl.has(alias));
            if (hasCompletedSameAppOrUrl) {
                this.logger.debug(`Worker '${workerId}' EXCLUDED due to already completed app/URL (${targetIdentity.packageId || targetIdentity.normalizedUrl})`);
                continue;
            }

            eligibleWorkers.push(workerId);
        }

        if (eligibleWorkers.length === 0) {
            this.logger.warn(`Zero eligible unique workers remaining for Campaign '${campaignId}'. All ${workerIds.length} candidate workers have already participated.`);
        }

        return eligibleWorkers;
    }
}
