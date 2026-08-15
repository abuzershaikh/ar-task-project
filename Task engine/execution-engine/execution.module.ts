import { Module, forwardRef } from '@nestjs/common';
import { ExecutionEngineService } from './execution.service';
import { TaskEngineModule } from '../task-engine/task-engine.module';
import { DatabaseModule } from '../shared/database/database.module';
import { ReviewEngineModule } from '../review-engine/review-engine.module';

@Module({
    imports: [
        forwardRef(() => TaskEngineModule),
        forwardRef(() => DatabaseModule),
        forwardRef(() => ReviewEngineModule),
    ],
    providers: [ExecutionEngineService],
    exports: [ExecutionEngineService],
})
export class ExecutionEngineModule { }
