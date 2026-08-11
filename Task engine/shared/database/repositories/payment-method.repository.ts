import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { PaymentMethod } from '../entities/payment-method.entity';

@Injectable()
export class PaymentMethodRepository {
    constructor(
        @InjectRepository(PaymentMethod)
        private readonly repository: Repository<PaymentMethod>,
    ) { }

    async findById(id: string): Promise<PaymentMethod | null> {
        return this.repository.findOne({ where: { id } });
    }

    async findByWorkerId(workerId: string): Promise<PaymentMethod[]> {
        return this.repository.find({
            where: { workerId },
            order: { isDefault: 'DESC', createdAt: 'DESC' },
        });
    }

    async findDefaultByWorkerId(workerId: string): Promise<PaymentMethod | null> {
        return this.repository.findOne({
            where: { workerId, isDefault: true },
        });
    }

    async unsetDefaultsForWorker(workerId: string): Promise<void> {
        await this.repository.update({ workerId }, { isDefault: false });
    }

    async create(data: Partial<PaymentMethod>): Promise<PaymentMethod> {
        const paymentMethod = this.repository.create(data);
        return this.repository.save(paymentMethod);
    }

    async update(id: string, data: Partial<PaymentMethod>): Promise<PaymentMethod> {
        await this.repository.update(id, data);
        return this.findById(id);
    }

    async delete(id: string): Promise<void> {
        await this.repository.delete(id);
    }
}
