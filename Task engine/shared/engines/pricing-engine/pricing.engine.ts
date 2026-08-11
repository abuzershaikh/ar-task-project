import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { ServiceCatalogRepository } from '../../database/repositories/service-catalog.repository';
import { PricingVersionService } from './pricing-version.service';
import { MarginCalculator } from './margin-calculator';
import { RewardCalculator } from './reward-calculator';
import { PriceCalculator } from './price-calculator';
import { PriceSnapshotService } from './price-snapshot.service';
import { PricingPolicy } from './policies/pricing-policy';
import { BuyerPriceInformation, InternalFinancialCalculation } from './types/price-calculation';
import { PriceSnapshot } from './types/price-snapshot';

@Injectable()
export class PricingEngine {
    constructor(
        private readonly serviceCatalogRepo: ServiceCatalogRepository,
        private readonly pricingVersionService: PricingVersionService,
        private readonly marginCalculator: MarginCalculator,
        private readonly rewardCalculator: RewardCalculator,
        private readonly priceCalculator: PriceCalculator,
        private readonly priceSnapshotService: PriceSnapshotService,
    ) { }

    /**
     * Buyer-safe pricing calculation. Returns ONLY buyer-relevant fields (no worker reward, no admin margin).
     */
    async calculateBuyerPrice(serviceIdentifier: string, quantity: number): Promise<BuyerPriceInformation> {
        PricingPolicy.validateQuantity(quantity);

        const service = await this.resolveService(serviceIdentifier);
        if (!service.isActive) {
            throw new BadRequestException(`Service '${service.name}' is currently inactive`);
        }

        const activePricing = await this.pricingVersionService.getActivePricingVersion(service.id);
        const buyerUnitPrice = Number(activePricing.buyerUnitPrice);
        const totalAmount = this.priceCalculator.calculateBuyerTotal(buyerUnitPrice, quantity);

        return {
            serviceCode: service.code,
            serviceName: service.name,
            buyerUnitPrice,
            currency: activePricing.currency || 'INR',
            quantity,
            totalAmount,
        };
    }

    /**
     * Admin/Internal full financial calculation with complete margin and payout breakdown.
     */
    async calculateFullFinancials(serviceIdentifier: string, quantity: number): Promise<InternalFinancialCalculation> {
        PricingPolicy.validateQuantity(quantity);

        const service = await this.resolveService(serviceIdentifier);
        const activePricing = await this.pricingVersionService.getActivePricingVersion(service.id);

        const buyerUnitPrice = Number(activePricing.buyerUnitPrice);
        const marginAmount = this.marginCalculator.calculateMarginAmount(
            buyerUnitPrice,
            activePricing.marginType,
            activePricing.marginValue,
        );

        const workerReward = Number(activePricing.workerReward);
        const totalBuyerAmount = this.priceCalculator.calculateBuyerTotal(buyerUnitPrice, quantity);
        const totalWorkerPayout = workerReward * quantity;
        const totalPlatformRevenue = marginAmount * quantity;

        return {
            serviceId: service.id,
            serviceCode: service.code,
            serviceName: service.name,
            buyerUnitPrice,
            marginType: activePricing.marginType,
            marginValue: Number(activePricing.marginValue),
            marginAmount,
            workerReward,
            currency: activePricing.currency || 'INR',
            pricingVersion: activePricing.version,
            quantity,
            totalBuyerAmount,
            totalWorkerPayout,
            totalPlatformRevenue,
        };
    }

    /**
     * Creates an immutable price snapshot for order creation.
     */
    async createOrderPriceSnapshot(serviceIdentifier: string, quantity: number): Promise<PriceSnapshot> {
        PricingPolicy.validateQuantity(quantity);

        const service = await this.resolveService(serviceIdentifier);
        if (!service.isActive) {
            throw new BadRequestException(`Service '${service.name}' is inactive`);
        }

        const activePricing = await this.pricingVersionService.getActivePricingVersion(service.id);
        return this.priceSnapshotService.createSnapshot(service, activePricing, quantity);
    }

    private async resolveService(serviceIdentifier: string) {
        let service = await this.serviceCatalogRepo.findById(serviceIdentifier);
        if (!service) {
            service = await this.serviceCatalogRepo.findByCode(serviceIdentifier);
        }

        if (!service) {
            throw new NotFoundException(`Service '${serviceIdentifier}' not found in catalog`);
        }

        return service;
    }
}
