import { Module } from '@nestjs/common';
import { DatabaseModule } from '../shared/database/database.module';
import { AllocationEngineService } from './allocation.service';
import { AssignmentService } from './services/assignment.service';
import { BatchService } from './services/batch.service';

import { MatchingEngineModule } from '../matching-engine/matching-engine.module';
import { TaskEngineModule } from '../task-engine/task-engine.module';
import { NotificationEngineModule } from '../notification-engine/notification-engine.module';

@Module({
    imports: [DatabaseModule, MatchingEngineModule, TaskEngineModule, NotificationEngineModule],
    providers: [AllocationEngineService, AssignmentService, BatchService],
    exports: [AllocationEngineService],
})
export class AllocationEngineModule { }
