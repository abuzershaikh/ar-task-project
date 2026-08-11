import { Module } from '@nestjs/common';
import { DatabaseModule } from '../shared/database/database.module';
import { ProgressEngineService } from './progress.service';
import { OrderProgressService } from './services/order-progress.service';
import { CampaignProgressService } from './services/campaign-progress.service';
import { WorkerProgressService } from './services/worker-progress.service';

@Module({
    imports: [DatabaseModule],
    providers: [
        ProgressEngineService,
        OrderProgressService,
        CampaignProgressService,
        WorkerProgressService,
    ],
    exports: [ProgressEngineService],
})
export class ProgressEngineModule { }
