import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ServicePricing } from '../entities/service-pricing.entity';

@Injectable()
export class ServicePricingRepository {
    constructor(
        @InjectRepository(ServicePricing)
        private readonly repository: Repository<ServicePricing>,
    ) { }

    async findActiveByServiceId(serviceId: string): Promise<ServicePricing | null> {
        return this.repository.findOne({
            where: { serviceId, isActive: true },
            order: { version: 'DESC' },
        });
    }

    async findHistoryByServiceId(serviceId: string): Promise<ServicePricing[]> {
        return this.repository.find({
            where: { serviceId },
            order: { version: 'DESC' },
        });
    }

    async findByServiceAndVersion(serviceId: string, version: number): Promise<ServicePricing | null> {
        return this.repository.findOne({
            where: { serviceId, version },
        });
    }

    async deactivateAllVersions(serviceId: string): Promise<void> {
        await this.repository.update(
            { serviceId, isActive: true },
            { isActive: false, effectiveUntil: new Date() },
        );
    }

    async create(data: Partial<ServicePricing>): Promise<ServicePricing> {
        const item = this.repository.create(data);
        return this.repository.save(item);
    }

    async update(id: string, data: Partial<ServicePricing>): Promise<ServicePricing | null> {
        await this.repository.update(id, data);
        return this.repository.findOne({ where: { id } });
    }
}
