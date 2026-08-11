import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ServiceCatalog } from '../entities/service-catalog.entity';

@Injectable()
export class ServiceCatalogRepository {
    constructor(
        @InjectRepository(ServiceCatalog)
        private readonly repository: Repository<ServiceCatalog>,
    ) { }

    async findAll(): Promise<ServiceCatalog[]> {
        return this.repository.find({ order: { name: 'ASC' } });
    }

    async findActive(): Promise<ServiceCatalog[]> {
        return this.repository.find({ where: { isActive: true }, order: { name: 'ASC' } });
    }

    async findById(id: string): Promise<ServiceCatalog | null> {
        return this.repository.findOne({ where: { id } });
    }

    async findByCode(code: string): Promise<ServiceCatalog | null> {
        return this.repository.findOne({ where: { code: code.toUpperCase() } });
    }

    async create(data: Partial<ServiceCatalog>): Promise<ServiceCatalog> {
        const item = this.repository.create({
            ...data,
            code: data.code ? data.code.toUpperCase() : undefined,
        });
        return this.repository.save(item);
    }

    async update(id: string, data: Partial<ServiceCatalog>): Promise<ServiceCatalog | null> {
        await this.repository.update(id, data);
        return this.findById(id);
    }

    async delete(id: string): Promise<boolean> {
        const result = await this.repository.delete(id);
        return (result.affected || 0) > 0;
    }
}
