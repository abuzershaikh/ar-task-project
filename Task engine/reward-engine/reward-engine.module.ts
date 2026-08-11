import { Module } from '@nestjs/common';
import { DatabaseModule } from '../shared/database/database.module';
import { RewardEngineService } from './reward.service';
import { RewardCalculator } from './calculators/reward-calculator';
import { RewardSnapshotService } from './services/reward-snapshot.service';

@Module({
    imports: [DatabaseModule],
    providers: [RewardEngineService, RewardCalculator, RewardSnapshotService],
    exports: [RewardEngineService],
})
export class RewardEngineModule { }
