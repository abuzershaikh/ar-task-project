import { Module } from '@nestjs/common';
import { DatabaseModule } from '../shared/database/database.module';
import { AllocationEngineService } from './allocation.service';
import { AssignmentService } from './services/assignment.service';
import { BatchService } from './services/batch.service';

@Module({
    imports: [DatabaseModule],
    providers: [AllocationEngineService, AssignmentService, BatchService],
    exports: [AllocationEngineService],
})
export class AllocationEngineModule { }
