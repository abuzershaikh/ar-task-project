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
                const pastTasks = await this.taskRepo.findByWorker(workerIds);
                for (const pt of pastTasks) {
                    const pastIdentity = extractTaskIdentity(pt);
                    const workerKey = (pt.assignedTo || '').toString();
                    if (!workerKey) continue;

                    if (targetIdentity.packageId && pastIdentity.packageId === targetIdentity.packageId) {
                        workersWithSameAppOrUrl.add(workerKey);
                    }
                    if (targetIdentity.normalizedUrl && pastIdentity.normalizedUrl === targetIdentity.normalizedUrl) {
                        workersWithSameAppOrUrl.add(workerKey);
                    }
                }
            } catch (err) {
                this.logger.warn(`Error checking cross-campaign task identity: ${err.message}`);
            }
        }

        const eligibleWorkers: string[] = [];

        for (const workerId of workerIds) {
            // Strict Exclusion Rule 1: Worker has ALREADY participated in CampaignWorkerParticipation DB table
            if (campaignId && usedWorkerIdsInCampaign.includes(workerId)) {
                this.logger.debug(`Worker '${workerId}' EXCLUDED from Campaign '${campaignId}' (Already participated/expired)`);
                continue;
            }

            // Strict Exclusion Rule 2: Check active task assignments in Task table via bulk map
            const hasActiveOrCompletedInCampaign = taskParticipationMap.get(workerId) === true;
            if (hasActiveOrCompletedInCampaign) {
                continue;
            }

            // Strict Exclusion Rule 3: Same app package or same target URL completed
            if (workersWithSameAppOrUrl.has(workerId)) {
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
