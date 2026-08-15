import { Module, forwardRef } from '@nestjs/common';
import { DatabaseModule } from '../shared/database/database.module';
import { EarningEngineModule } from '../earning-engine/earning-engine.module';
import { TaskEngineModule } from '../task-engine/task-engine.module';
import { FraudEngineModule } from '../fraud-engine/fraud-engine.module';
import { NotificationEngineModule } from '../notification-engine/notification-engine.module';
import { ProgressEngineModule } from '../progress-engine/progress-engine.module';
import { ReviewEngineService } from './review.service';
import { ReviewAssignmentService } from './services/review-assignment.service';
import { ReviewDecisionService } from './services/review-decision.service';

@Module({
    imports: [
        DatabaseModule, 
        EarningEngineModule, 
        FraudEngineModule,
        NotificationEngineModule,
        ProgressEngineModule,
        forwardRef(() => TaskEngineModule) // using forwardRef if circular dependency exists, though TaskEngine doesn't seem to import ReviewEngine
    ],
    providers: [ReviewEngineService, ReviewAssignmentService, ReviewDecisionService],
    exports: [ReviewEngineService],
})
export class ReviewEngineModule { }
