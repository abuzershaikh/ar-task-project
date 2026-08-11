import { Module } from '@nestjs/common';
import { DatabaseModule } from '../shared/database/database.module';
import { EarningEngineModule } from '../earning-engine/earning-engine.module';
import { ReviewEngineService } from './review.service';
import { ReviewAssignmentService } from './services/review-assignment.service';
import { ReviewDecisionService } from './services/review-decision.service';

@Module({
    imports: [DatabaseModule, EarningEngineModule],
    providers: [ReviewEngineService, ReviewAssignmentService, ReviewDecisionService],
    exports: [ReviewEngineService],
})
export class ReviewEngineModule { }
