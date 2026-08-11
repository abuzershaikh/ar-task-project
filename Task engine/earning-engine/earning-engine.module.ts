import { Module } from '@nestjs/common';
import { DatabaseModule } from '../shared/database/database.module';
import { RewardEngineModule } from '../reward-engine/reward-engine.module';
import { EarningEngineService } from './earning.service';
import { EarningCalculator } from './calculators/earning-calculator';
import { EarningPostingService } from './services/earning-posting.service';

@Module({
    imports: [DatabaseModule, RewardEngineModule],
    providers: [EarningEngineService, EarningCalculator, EarningPostingService],
    exports: [EarningEngineService],
})
export class EarningEngineModule { }
