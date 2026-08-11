import { Injectable } from '@nestjs/common';
import { WorkerRepository } from '../../shared/database/repositories/worker.repository';
import { ActiveFilterService } from '../filters/active-filter.service';
import { KycFilterService } from '../filters/kyc-filter.service';
import { LocationFilterService } from '../filters/location-filter.service';
import { CategoryFilterService } from '../filters/category-filter.service';
import { CapacityFilterService } from '../filters/capacity-filter.service';
import { DuplicateFilterService } from '../filters/duplicate-filter.service';
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
    ) { }

    async findCandidates(context: MatchingContext): Promise<CandidateWorker[]> {
        // Step 1: Get all active workers
        let workers = await this.workerRepo.findActiveWorkers();
        let workerIds = workers.map(w => w.id);

        console.log(`🔍 Initial pool: ${workerIds.length} workers`);

        // Step 2: Apply filters
        const filterResults: Record<string, boolean>[] = [];

        // Active filter
        workerIds = await this.activeFilter.apply(workerIds, context);
        console.log(`✅ After active filter: ${workerIds.length} workers`);

        // KYC filter
        workerIds = await this.kycFilter.apply(workerIds, context);
        console.log(`✅ After KYC filter: ${workerIds.length} workers`);

        // Capacity filter
        workerIds = await this.capacityFilter.apply(workerIds, context);
        console.log(`✅ After capacity filter: ${workerIds.length} workers`);

        // Location filter (if applicable)
        if (context.filters.includes('location')) {
            workerIds = await this.locationFilter.apply(workerIds, context);
            console.log(`✅ After location filter: ${workerIds.length} workers`);
        }

        // Category filter (if applicable)
        if (context.filters.includes('category')) {
            workerIds = await this.categoryFilter.apply(workerIds, context);
            console.log(`✅ After category filter: ${workerIds.length} workers`);
        }

        // Duplicate filter
        workerIds = await this.duplicateFilter.apply(workerIds, context);
        console.log(`✅ After duplicate filter: ${workerIds.length} workers`);

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
