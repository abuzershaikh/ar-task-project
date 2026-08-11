import { Module } from '@nestjs/common';
import { DatabaseModule } from '../shared/database/database.module';
import { RankingEngineService } from './ranking.service';
import { RankingCalculator } from './calculators/ranking-calculator';

@Module({
    imports: [DatabaseModule],
    providers: [RankingEngineService, RankingCalculator],
    exports: [RankingEngineService],
})
export class RankingEngineModule { }
