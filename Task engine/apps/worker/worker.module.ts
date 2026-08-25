import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { DatabaseModule } from '../../shared/database/database.module';
import { ServicesModule } from '../../shared/services/services.module';
import { AppQueueModule } from '../../shared/queue/app-queue.module';

// Engine Modules
import { TaskEngineModule } from '../../task-engine/task-engine.module';
import { MatchingEngineModule } from '../../matching-engine/matching-engine.module';
import { AllocationEngineModule } from '../../allocation-engine/allocation-engine.module';
import { EarningEngineModule } from '../../earning-engine/earning-engine.module';
import { RewardEngineModule } from '../../reward-engine/reward-engine.module';

// Queue Processors
import { TaskQueueProcessor } from './processors/task-queue.processor';
import { MatchingQueueProcessor } from './processors/matching-queue.processor';
import { AllocationQueueProcessor } from './processors/allocation-queue.processor';
import { EarningQueueProcessor } from './processors/earning-queue.processor';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    DatabaseModule,
    ServicesModule,
    AppQueueModule,
    TaskEngineModule,
    MatchingEngineModule,
    AllocationEngineModule,
    EarningEngineModule,
    RewardEngineModule,
  ],
  providers: [
    TaskQueueProcessor,
    MatchingQueueProcessor,
    AllocationQueueProcessor,
    EarningQueueProcessor,
  ],
})
export class WorkerModule {}
