import { Module } from '@nestjs/common';
import { DatabaseModule } from '../shared/database/database.module';
import { ScoringEngineService } from './scoring.service';
import { ScoreCalculator } from './calculators/score-calculator';
import { ScoreNormalizer } from './calculators/score-normalizer';
import { TaskReleaseListener } from './listeners/task-release.listener';

@Module({
    imports: [DatabaseModule],
    providers: [ScoringEngineService, ScoreCalculator, ScoreNormalizer, TaskReleaseListener],
    exports: [ScoringEngineService],
})
export class ScoringEngineModule { }
