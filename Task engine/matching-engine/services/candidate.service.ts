import { Injectable } from '@nestjs/common';
import { WorkerRepository } from '../../shared/database/repositories/worker.repository';
import { ActiveFilterService } from '../filters/active-filter.service';
import { KycFilterService } from '../filters/kyc-filter.service';
import { LocationFilterService } from '../filters/location-filter.service';
import { CategoryFilterService } from '../filters/category-filter.service';
import { CapacityFilterService } from '../filters/capacity-filter.service';
import { DuplicateFilterService } from '../filters/duplicate-filter.service';
import { EligibilityEngineService } from '../../eligibility-engine/eligibility.service';
import { MatchingContext, CandidateWorker } from '../types';

/**
 * Candidate workers find karta hai filters apply karke
 */
@Injectable()
export class CandidateService {
    constructor(
        private readonly workerRepo: WorkerRepository,
        private readonly activeFilter: ActiveFilterService,
        private readonly kycFilter: KycFilterService,
        private readonly locationFilter: LocationFilterService,
        private readonly categoryFilter: CategoryFilterService,
        private readonly capacityFilter: CapacityFilterService,
        private readonly duplicateFilter: DuplicateFilterService,
        private readonly eligibilityEngine: EligibilityEngineService,
    ) { }

    async findCandidates(
        context: MatchingContext,
        preloadedWorkers?: any[],
        preloadedActiveCountsMap?: Map<string, number>,
        preloadedUsedWorkerIdsInCampaign?: string[],
        preloadedTaskParticipationMap?: Map<string, boolean>
    ): Promise<CandidateWorker[]> {
        // Step 1: Get all active workers
        let workers = preloadedWorkers || await this.workerRepo.findActiveWorkers();
        let workerIds = workers.map(w => w.id);

        console.log(`🔍 Initial pool: ${workerIds.length} workers`);

        // Active filter (pass loaded workers)
        // Note: If we use findActiveWorkers, they are already active, but let's keep the filter just in case
        // Wait, the double filtering is redundant. Let's just rely on the preloaded workers being active.
        // Actually, if we pass preloaded workers, we'll skip the active filter DB call anyway because we pass workers.
        workerIds = await this.activeFilter.apply(workerIds, context, workers);
        workers = workers.filter(w => workerIds.includes(w.id));
        console.log(`✅ After active filter: ${workerIds.length} workers`);

        // KYC filter (pass loaded workers)
        workerIds = await this.kycFilter.apply(workerIds, context, workers);
        workers = workers.filter(w => workerIds.includes(w.id));
        console.log(`✅ After KYC filter: ${workerIds.length} workers`);

        // Capacity filter (uses preloaded bulk query)
        workerIds = await this.capacityFilter.apply(workerIds, context, preloadedActiveCountsMap);
        workers = workers.filter(w => workerIds.includes(w.id));
        console.log(`✅ After capacity filter: ${workerIds.length} workers`);

        // Location filter (if applicable)
        if (context.filters.includes('location')) {
            workerIds = await this.locationFilter.apply(workerIds, context, workers);
            workers = workers.filter(w => workerIds.includes(w.id));
            console.log(`✅ After location filter: ${workerIds.length} workers`);
        }

        // Category filter (if applicable)
        if (context.filters.includes('category')) {
            workerIds = await this.categoryFilter.apply(workerIds, context, workers);
            workers = workers.filter(w => workerIds.includes(w.id));
            console.log(`✅ After category filter: ${workerIds.length} workers`);
        }

        // Duplicate filter (uses preloaded bulk query)
        workerIds = await this.duplicateFilter.apply(
            workerIds, 
            context, 
            preloadedUsedWorkerIdsInCampaign, 
            preloadedTaskParticipationMap
        );
        console.log(`✅ After duplicate filter: ${workerIds.length} workers`);

        // Eligibility Engine check (Fail-closed: MUST explicitly be true)
        const eligibilityMap = await this.eligibilityEngine.batchCheckEligibility(workerIds, context.taskId);
        workerIds = workerIds.filter(id => eligibilityMap.get(id)?.isEligible === true);
        console.log(`✅ After Eligibility Engine check: ${workerIds.length} workers`);

        // Step 3: Build candidate objects
        const candidates: CandidateWorker[] = workerIds.map(workerId => ({
            workerId,
            score: 0, // Will be calculated later
            rank: 0, // Will be assigned later
            eligible: true,
            filterResults: {},
        }));

        return candidates;
    }
}
