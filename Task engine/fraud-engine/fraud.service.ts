import { Injectable } from '@nestjs/common';
import { RiskScoreService } from './services/risk-score.service';

/**
 * Fraud Engine
 * Suspicious activity detect karta hai
 */
@Injectable()
export class FraudEngineService {
    constructor(private readonly riskScoreService: RiskScoreService) { }

    async calculateRiskScore(workerId: string, actionType: string): Promise<number> {
        const score = await this.riskScoreService.calculate(workerId, actionType);
        return score;
    }

    async isSuspicious(workerId: string, actionType: string): Promise<boolean> {
        const score = await this.calculateRiskScore(workerId, actionType);
        return score > 70; // threshold
    }
}
