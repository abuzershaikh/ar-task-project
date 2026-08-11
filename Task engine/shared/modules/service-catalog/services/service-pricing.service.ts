import { Injectable, NotFoundException } from '@nestjs/common';
import { ServicePricingRepository } from '../../../database/repositories/service-pricing.repository';
import { ServiceCatalogRepository } from '../../../database/repositories/service-catalog.repository';
import { ServicePricing } from '../../../database/entities/service-pricing.entity';
import { MarginType } from '../enums/margin-type.enum';
import { MarginPolicy } from '../../../engines/pricing-engine/policies/margin-policy';
import { MarginCalculator } from '../../../engines/pricing-engine/margin-calculator';

@Injectable()
export class ServicePricingService {
    constructor(
        private readonly servicePricingRepo: ServicePricingRepository,
        private readonly serviceCatalogRepo: ServiceCatalogRepository,
        private readonly marginCalculator: MarginCalculator,
    ) { }

    async createNewPricingVersion(
        serviceId: string,
        data: {
            buyerUnitPrice: number;
            marginType: MarginType;
            marginValue: number;
            currency?: string;
        },
    ): Promise<ServicePricing> {
        const service = await this.serviceCatalogRepo.findById(serviceId);
        if (!service) {
            throw new NotFoundException(`Service with ID '${serviceId}' not found`);
        }

        const buyerUnitPrice = Number(data.buyerUnitPrice);
        const marginValue = Number(data.marginValue);

        // Enforce strict MarginPolicy validation rules
        MarginPolicy.validateMargin(buyerUnitPrice, data.marginType, marginValue);

        const marginAmount = this.marginCalculator.calculateMarginAmount(
            buyerUnitPrice,
            data.marginType,
            marginValue,
        );
        const workerReward = buyerUnitPrice - marginAmount;

        // Deactivate all existing versions for this service to ensure exactly ONE active version
        await this.servicePricingRepo.deactivateAllVersions(serviceId);

        const newVersion = (service.version || 0) + 1;

        const newPricing = await this.servicePricingRepo.create({
            serviceId,
            buyerUnitPrice,
            marginType: data.marginType,
            marginValue,
            workerReward,
            currency: data.currency || 'INR',
            version: newVersion,
            isActive: true,
            effectiveFrom: new Date(),
        });

        // Update service root version pointer
        await this.serviceCatalogRepo.update(serviceId, { version: newVersion });

        return newPricing;
    }

    async getActivePricing(serviceId: string): Promise<ServicePricing> {
        const pricing = await this.servicePricingRepo.findActiveByServiceId(serviceId);
        if (!pricing) {
            throw new NotFoundException(`No active pricing configuration found for service '${serviceId}'`);
        }
        return pricing;
    }

    async getPricingHistory(serviceId: string): Promise<ServicePricing[]> {
        return this.servicePricingRepo.findHistoryByServiceId(serviceId);
    }
}
