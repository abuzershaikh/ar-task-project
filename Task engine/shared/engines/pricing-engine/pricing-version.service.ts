import { Injectable, NotFoundException } from '@nestjs/common';
import { ServicePricingRepository } from '../../database/repositories/service-pricing.repository';
import { ServicePricing } from '../../database/entities/service-pricing.entity';

@Injectable()
export class PricingVersionService {
    constructor(private readonly servicePricingRepo: ServicePricingRepository) { }

    async getActivePricingVersion(serviceId: string): Promise<ServicePricing> {
        const pricing = await this.servicePricingRepo.findActiveByServiceId(serviceId);
        if (!pricing) {
            throw new NotFoundException(`No active pricing configuration found for service ID '${serviceId}'`);
        }
        return pricing;
    }

    async getPricingVersion(serviceId: string, version: number): Promise<ServicePricing> {
        const pricing = await this.servicePricingRepo.findByServiceAndVersion(serviceId, version);
        if (!pricing) {
            throw new NotFoundException(`Pricing version ${version} for service '${serviceId}' not found`);
        }
        return pricing;
    }

    async getPricingHistory(serviceId: string): Promise<ServicePricing[]> {
        return this.servicePricingRepo.findHistoryByServiceId(serviceId);
    }
}
