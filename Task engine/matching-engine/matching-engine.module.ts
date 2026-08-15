import { Module } from '@nestjs/common';
import { DatabaseModule } from '../shared/database/database.module';
import { MatchingEngineService } from './matching-engine.service';
import { CandidateService } from './services/candidate.service';
import { MatchingContextService } from './services/matching-context.service';
import { MatchingDecisionService } from './services/matching-decision.service';

// Filters
import { ActiveFilterService } from './filters/active-filter.service';
import { LocationFilterService } from './filters/location-filter.service';
import { CategoryFilterService } from './filters/category-filter.service';
import { CapacityFilterService } from './filters/capacity-filter.service';
import { DuplicateFilterService } from './filters/duplicate-filter.service';

import { ScoringEngineModule } from '../scoring-engine/scoring-engine.module';
import { RankingEngineModule } from '../ranking-engine/ranking-engine.module';
import { EligibilityEngineModule } from '../eligibility-engine/eligibility-engine.module';

@Module({
    imports: [DatabaseModule, ScoringEngineModule, RankingEngineModule, EligibilityEngineModule],
    providers: [
        MatchingEngineService,
        CandidateService,
        MatchingContextService,
        MatchingDecisionService,
        ActiveFilterService,
        LocationFilterService,
        CategoryFilterService,
        CapacityFilterService,
        DuplicateFilterService,
    ],
    exports: [MatchingEngineService],
})
export class MatchingEngineModule { }
