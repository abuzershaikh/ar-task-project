import { Module, forwardRef } from '@nestjs/common';
import { TaskEngineService } from './task-engine.service';
import { TaskStateMachine } from './state-machine/task-state-machine';
import { TaskCommandService } from './handlers/task-command.service';
import { TaskQueryService } from './queries/task-query.service';
import { TaskValidationService } from './task-validation.service';
import { TaskTransitionService } from './handlers/task-transition.service';
import { TaskDeadlineService } from './handlers/task-deadline.service';
import { TaskAttemptService } from './handlers/task-attempt.service';
import { TaskCancellationService } from './handlers/task-cancellation.service';
import { DatabaseModule } from '../shared/database/database.module';
import { MatchingEngineModule } from '../matching-engine/matching-engine.module';

@Module({
    imports: [DatabaseModule, forwardRef(() => MatchingEngineModule)],
    providers: [
        TaskEngineService,
        TaskStateMachine,
        TaskCommandService,
        TaskQueryService,
        TaskValidationService,
        TaskTransitionService,
        TaskDeadlineService,
        TaskAttemptService,
        TaskCancellationService,
    ],
    exports: [TaskEngineService, TaskQueryService, TaskDeadlineService],
})
export class TaskEngineModule { }
