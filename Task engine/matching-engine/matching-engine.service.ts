import { Injectable } from '@nestjs/common';
import { CandidateService } from './services/candidate.service';
import { MatchingContextService } from './services/matching-context.service';
import { MatchingDecisionService } from './services/matching-decision.service';
import { MatchingRequest, MatchingResult } from './types';

import { WorkerRepository } from '../shared/database/repositories/worker.repository';
import { TaskRepository } from '../shared/database/repositories/task.repository';
import { CampaignWorkerParticipationRepository } from '../shared/database/repositories/campaign-worker-participation.repository';

/**
 * Matching Engine
 * Task ke liye eligible workers find karta hai aur priority decide karta hai
 */
@Injectable()
export class MatchingEngineService {
    constructor(
        private readonly candidateService: CandidateService,
        private readonly contextService: MatchingContextService,
        private readonly decisionService: MatchingDecisionService,
        private readonly workerRepo: WorkerRepository,
        private readonly taskRepo: TaskRepository,
        private readonly participationRepo: CampaignWorkerParticipationRepository,
    ) { }

    async matchWorkersForTask(
        request: MatchingRequest, 
        preloadedWorkers?: any[],
        preloadedActiveCountsMap?: Map<string, number>,
        preloadedUsedWorkerIdsInCampaign?: string[],
        preloadedTaskParticipationMap?: Map<string, boolean>
    ): Promise<MatchingResult> {
        // 1. Context build karo
        const context = await this.contextService.buildContext(request);

        // 2. Candidate workers find karo
        const candidates = await this.candidateService.findCandidates(
            context,
            preloadedWorkers,
            preloadedActiveCountsMap,
            preloadedUsedWorkerIdsInCampaign,
            preloadedTaskParticipationMap
        );

        // 3. Matching decision lo
        const result = await this.decisionService.decide(candidates, context, preloadedWorkers);

        return result;
    }

    async matchWorkersForBatch(taskIds: string[]): Promise<Map<string, MatchingResult>> {
        const results = new Map<string, MatchingResult>();
        
        if (taskIds.length === 0) return results;

        console.log(`🚀 Preloading bulk data for batch matching of ${taskIds.length} tasks...`);
        
        // 1. Preload all active workers once
        const preloadedWorkers = await this.workerRepo.findActiveWorkers();
        const activeWorkerIds = preloadedWorkers.map(w => w.id);

        // 2. Preload active task counts once
        const preloadedActiveCountsMap = await this.taskRepo.getWorkerActiveTaskCounts(activeWorkerIds);

        // 3. Preload all tasks in batch to isolate campaign/order context per task
        const tasks = await Promise.all(taskIds.map(id => this.taskRepo.findById(id)));
        const taskMap = new Map<string, any>();
        const campaignUsedWorkersMap = new Map<string, string[]>();
        const campaignParticipationMaps = new Map<string, Map<string, boolean>>();

        for (const t of tasks) {
            if (!t) continue;
            taskMap.set(t.id, t);
            const campaignId = t.campaignId || t.orderId;
            if (campaignId && !campaignUsedWorkersMap.has(campaignId)) {
                const used = await this.participationRepo.findUsedWorkerIdsByCampaign(campaignId);
                campaignUsedWorkersMap.set(campaignId, used);
                const partMap = await this.taskRepo.getWorkerCampaignParticipationMap(
                    activeWorkerIds,
                    campaignId,
                    t.orderId,
                );
                campaignParticipationMaps.set(campaignId, partMap);
            }
        }

        console.log(`✅ Bulk data preloaded. Proceeding to evaluate each task in-memory.`);

        for (const taskId of taskIds) {
            const t = taskMap.get(taskId);
            const campaignId = t?.campaignId || t?.orderId;
            const preloadedUsedWorkerIdsInCampaign = campaignId ? (campaignUsedWorkersMap.get(campaignId) || []) : [];
            const preloadedTaskParticipationMap = campaignId ? campaignParticipationMaps.get(campaignId) : undefined;

            const result = await this.matchWorkersForTask(
                { taskId },
                preloadedWorkers,
                preloadedActiveCountsMap,
                preloadedUsedWorkerIdsInCampaign,
                preloadedTaskParticipationMap
            );
            results.set(taskId, result);
        }

        return results;
    }
}
