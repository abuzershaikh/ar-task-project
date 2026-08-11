import { Module } from '@nestjs/common';
import { DatabaseModule } from '../shared/database/database.module';
import { MatchingEngineService } from './matching-engine.service';
import { CandidateService } from './services/candidate.service';
import { MatchingContextService } from './services/matching-context.service';
import { MatchingDecisionService } from './services/matching-decision.service';

// Filters
import { ActiveFilterService } from './filters/active-filter.service';
import { KycFilterService } from './filters/kyc-filter.service';
import { LocationFilterService } from './filters/location-filter.service';
import { CategoryFilterService } from './filters/category-filter.service';
import { CapacityFilterService } from './filters/capacity-filter.service';
import { DuplicateFilterService } from './filters/duplicate-filter.service';

@Module({
    imports: [DatabaseModule],
    providers: [
        MatchingEngineService,
        CandidateService,
        MatchingContextService,
        MatchingDecisionService,
        ActiveFilterService,
        KycFilterService,
        LocationFilterService,
        CategoryFilterService,
        CapacityFilterService,
        DuplicateFilterService,
    ],
    exports: [MatchingEngineService],
})
export class MatchingEngineModule { }
