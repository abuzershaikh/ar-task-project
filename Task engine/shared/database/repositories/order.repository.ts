import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, FindManyOptions, In } from 'typeorm';
import { Order } from '../entities/order.entity';

@Injectable()
export class OrderRepository {
    constructor(
        @InjectRepository(Order)
        private readonly repository: Repository<Order>,
    ) { }

    async count(options?: FindManyOptions<Order>): Promise<number> {
        return this.repository.count(options);
    }

    async findById(id: string): Promise<Order | null> {
        return this.repository.findOne({ where: { id } });
    }

    async findByBuyer(buyerId: string): Promise<Order[]> {
        return this.repository.find({ where: { buyerId } });
    }

    async findAll(): Promise<Order[]> {
        return this.repository.find({
            order: { createdAt: 'DESC' },
        });
    }

    async findActiveOrders(): Promise<Order[]> {
        return this.repository.find({
            where: { status: In(['ACTIVE', 'active', 'IN_PROGRESS', 'in_progress']) },
            order: { createdAt: 'DESC' },
        });
    }

    async create(data: Partial<Order>): Promise<Order> {
        const order = this.repository.create(data);
        return this.repository.save(order);
    }

    async update(id: string, data: Partial<Order>): Promise<Order> {
        await this.repository.update(id, data);
        return this.findById(id);
    }

    async incrementCompletedTasks(orderId: string): Promise<void> {
        await this.repository.increment({ id: orderId }, 'tasksCompleted', 1);
    }

    async getPlatformFinancialMetrics(): Promise<{ grossVolume: number; platformMargin: number }> {
        const result = await this.repository
            .createQueryBuilder('o')
            .select('SUM(o.total_amount)', 'grossVolume')
            .addSelect('SUM(o.tasks_completed * o.platform_margin_snapshot)', 'platformMargin')
            .where('o.status != :status', { status: 'CANCELLED' })
            .getRawOne();

        return {
            grossVolume: parseFloat(result?.grossVolume || 0),
            platformMargin: parseFloat(result?.platformMargin || 0),
        };
    }
}
