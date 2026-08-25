import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, FindManyOptions } from 'typeorm';
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
}
