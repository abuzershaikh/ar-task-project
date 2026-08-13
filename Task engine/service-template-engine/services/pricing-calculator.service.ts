import { Injectable } from '@nestjs/common';
import { IPricingConfig, IPriceChip } from '../domain/interfaces/pricing-config.interface';
import { PricingModelType } from '../domain/enums/pricing-model-type.enum';

export interface IPricingCalculationResult {
  totalCost: number;
  workerRewardPerUnit: number;
  adminMarginAmount: number;
  appliedQuantity: number;
  selectedChip?: IPriceChip;
}

@Injectable()
export class PricingCalculatorService {
  /**
   * Dynamic Price & Payout Calculator Engine
   * Calculates Buyer total cost and Worker reward according to Admin pricing rules.
   */
  calculatePrice(pricing: IPricingConfig, targetQuantity = 1, selectedChipId?: string): IPricingCalculationResult {
    const margin = pricing.adminMarginPercent || 20.0;
    let totalCost = pricing.buyerPrice || 0.0;
    let appliedQuantity = targetQuantity;
    let selectedChip: IPriceChip | undefined;

    if (pricing.modelType === PricingModelType.TIERED_CHIPS && pricing.chips?.length) {
      selectedChip = pricing.chips.find((c) => c.id === selectedChipId) || pricing.chips[0];
      totalCost = selectedChip.price;
      appliedQuantity = selectedChip.quantity;
    } else if (pricing.modelType === PricingModelType.COUNT_BASED) {
      const unit = pricing.unitPrice || pricing.buyerPrice || 1.0;
      appliedQuantity = Math.max(pricing.minQuantity || 1, targetQuantity);
      totalCost = unit * appliedQuantity;
    }

    const adminMarginAmount = (totalCost * margin) / 100.0;
    const totalWorkerRewardPool = totalCost - adminMarginAmount;
    const workerRewardPerUnit = appliedQuantity > 0 ? totalWorkerRewardPool / appliedQuantity : totalWorkerRewardPool;

    return {
      totalCost,
      workerRewardPerUnit,
      adminMarginAmount,
      appliedQuantity,
      selectedChip,
    };
  }
}
