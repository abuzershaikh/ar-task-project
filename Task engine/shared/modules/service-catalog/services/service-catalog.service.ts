import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { ServiceCatalogRepository } from '../../../database/repositories/service-catalog.repository';
import { ServiceCatalog } from '../../../database/entities/service-catalog.entity';

@Injectable()
export class ServiceCatalogService {
    constructor(private readonly serviceCatalogRepo: ServiceCatalogRepository) { }

    async getAllServices(): Promise<ServiceCatalog[]> {
        return this.serviceCatalogRepo.findAll();
    }

    async getActiveServices(): Promise<ServiceCatalog[]> {
        return this.serviceCatalogRepo.findActive();
    }

    async getServiceById(id: string): Promise<ServiceCatalog> {
        const service = await this.serviceCatalogRepo.findById(id);
        if (!service) {
            throw new NotFoundException(`Service with ID '${id}' not found`);
        }
        return service;
    }

    async getServiceByCode(code: string): Promise<ServiceCatalog> {
        const service = await this.serviceCatalogRepo.findByCode(code);
        if (!service) {
            throw new NotFoundException(`Service with code '${code}' not found`);
        }
        return service;
    }

    async createService(data: {
        code: string;
        name: string;
        description?: string;
    }): Promise<ServiceCatalog> {
        const existing = await this.serviceCatalogRepo.findByCode(data.code);
        if (existing) {
            throw new BadRequestException(`Service with code '${data.code.toUpperCase()}' already exists`);
        }

        return this.serviceCatalogRepo.create({
            code: data.code.toUpperCase(),
            name: data.name,
            description: data.description,
            isActive: true,
            version: 1,
        });
    }

    async updateService(
        id: string,
        data: { name?: string; description?: string; isActive?: boolean },
    ): Promise<ServiceCatalog> {
        await this.getServiceById(id);
        const updated = await this.serviceCatalogRepo.update(id, data);
        return updated!;
    }
}
