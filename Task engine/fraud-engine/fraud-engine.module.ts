import { Module } from '@nestjs/common';
import { DatabaseModule } from '../shared/database/database.module';
import { FraudEngineService } from './fraud.service';
import { RiskScoreService } from './services/risk-score.service';

@Module({
  imports: [DatabaseModule],
  providers: [FraudEngineService, RiskScoreService],
  exports: [FraudEngineService, RiskScoreService],
})
export class FraudEngineModule {}
