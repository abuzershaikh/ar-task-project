import { Injectable } from '@nestjs/common';
import { MarginCalculator } from './margin-calculator';
import { MarginType } from '../../modules/service-catalog/enums/margin-type.enum';
import { RewardCalculationResult } from './types/reward-calculation';

@Injectable()
export class RewardCalculator {
    constructor(private readonly marginCalculator: MarginCalculator) { }

    calculateWorkerReward(
        buyerUnitPrice: number,
        marginType: MarginType,
        marginValue: number,
    ): RewardCalculationResult {
        const price = Number(buyerUnitPrice);
        const marginAmount = this.marginCalculator.calculateMarginAmount(price, marginType, marginValue);
        const workerFinalReward = Math.max(0, price - marginAmount);

        return {
            buyerUnitPrice: price,
            marginAmount,
            workerFinalReward,
            isValid: workerFinalReward >= 0 && marginAmount <= price,
        };
    }
}
