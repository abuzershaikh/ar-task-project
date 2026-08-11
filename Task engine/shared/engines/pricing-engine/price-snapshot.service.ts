import { Injectable } from '@nestjs/common';
import { ServiceCatalog } from '../../database/entities/service-catalog.entity';
import { ServicePricing } from '../../database/entities/service-pricing.entity';
import { PriceSnapshot } from './types/price-snapshot';
import { MarginCalculator } from './margin-calculator';
import { PriceCalculator } from './price-calculator';

@Injectable()
export class PriceSnapshotService {
    constructor(
        private readonly marginCalculator: MarginCalculator,
        private readonly priceCalculator: PriceCalculator,
    ) { }

    createSnapshot(
        service: ServiceCatalog,
        pricing: ServicePricing,
        quantity: number,
    ): PriceSnapshot {
        const buyerUnitPrice = Number(pricing.buyerUnitPrice);
        const marginAmount = this.marginCalculator.calculateMarginAmount(
            buyerUnitPrice,
            pricing.marginType,
            pricing.marginValue,
        );

        const workerReward = Number(pricing.workerReward);
        const totalAmount = this.priceCalculator.calculateBuyerTotal(buyerUnitPrice, quantity);

        return {
            serviceId: service.id,
            serviceCode: service.code,
            pricingVersion: pricing.version,
            buyerUnitPrice,
            marginType: pricing.marginType,
            marginValue: Number(pricing.marginValue),
            marginAmount,
            workerRewardSnapshot: workerReward,
            currency: pricing.currency || 'INR',
            quantity,
            totalAmount,
            snapshotCreatedAt: new Date(),
        };
    }
}
