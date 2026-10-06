import { Injectable } from '@nestjs/common';
import { ServiceCatalog } from '../../database/entities/service-catalog.entity';
import { ServicePricing } from '../../database/entities/service-pricing.entity';
import { PriceSnapshot } from './types/price-snapshot';
import { MarginCalculator } from './margin-calculator';
import { PriceCalculator } from './price-calculator';
import { roundCurrency } from './youtube-duration-pricing';

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
        const buyerUnitPrice = roundCurrency(Number(pricing.buyerUnitPrice));
        if (buyerUnitPrice <= 0) {
            throw new Error('Configured buyer unit price must be greater than zero');
        }
        const configuredMarginAmount = roundCurrency(this.marginCalculator.calculateMarginAmount(
            buyerUnitPrice,
            pricing.marginType,
            pricing.marginValue,
        ));

        const maxWorkerReward = roundCurrency(Math.max(0, buyerUnitPrice - configuredMarginAmount));
        const storedWorkerReward = Number(pricing.workerReward);
        const workerReward = roundCurrency(Math.min(
            Number.isFinite(storedWorkerReward) && storedWorkerReward > 0 ? storedWorkerReward : maxWorkerReward,
            maxWorkerReward,
        ));
        if (workerReward <= 0) {
            throw new Error('Configured pricing must provide a positive worker reward');
        }
        const marginAmount = roundCurrency(buyerUnitPrice - workerReward);
        const totalAmount = roundCurrency(this.priceCalculator.calculateBuyerTotal(buyerUnitPrice, quantity));

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
