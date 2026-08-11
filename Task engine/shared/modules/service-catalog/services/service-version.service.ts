import { Injectable } from '@nestjs/common';
import { ServicePricingRepository } from '../../../database/repositories/service-pricing.repository';
import { ServicePricing } from '../../../database/entities/service-pricing.entity';

@Injectable()
export class ServiceVersionService {
    constructor(private readonly servicePricingRepo: ServicePricingRepository) { }

    async activateVersion(serviceId: string, version: number): Promise<ServicePricing> {
        const target = await this.servicePricingRepo.findByServiceAndVersion(serviceId, version);
        if (!target) {
            throw new Error(`Pricing version ${version} not found for service '${serviceId}'`);
        }

        await this.servicePricingRepo.deactivateAllVersions(serviceId);
        const activated = await this.servicePricingRepo.update(target.id, {
            isActive: true,
            effectiveFrom: new Date(),
            effectiveUntil: undefined,
        });

        return activated!;
    }
}
