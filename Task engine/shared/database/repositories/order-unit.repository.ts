import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { OrderUnit } from '../entities/order-unit.entity';

@Injectable()
export class OrderUnitRepository {
    constructor(
        @InjectRepository(OrderUnit)
        private readonly repository: Repository<OrderUnit>,
    ) {}

    async createBatch(units: Partial<OrderUnit>[]): Promise<OrderUnit[]> {
        const entities = this.repository.create(units);
        return this.repository.save(entities);
    }

    async findByOrderId(orderId: string): Promise<OrderUnit[]> {
        return this.repository.find({
            where: { orderId },
            order: { unitNumber: 'ASC' },
        });
    }

    async updateStatus(id: string, status: string): Promise<void> {
        await this.repository.update(id, { status });
    }
}
