import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { PaymentTransaction } from '../entities/payment-transaction.entity';

@Injectable()
export class PaymentTransactionRepository {
    constructor(
        @InjectRepository(PaymentTransaction)
        private readonly repository: Repository<PaymentTransaction>,
    ) { }

    async findByProviderPaymentId(provider: string, providerPaymentId: string): Promise<PaymentTransaction | null> {
        return this.repository.findOne({
            where: { provider, providerPaymentId },
        });
    }

    async findByProviderEventId(provider: string, providerEventId: string): Promise<PaymentTransaction | null> {
        return this.repository.findOne({
            where: { provider, providerEventId },
        });
    }

    async findByOrderId(orderId: string): Promise<PaymentTransaction[]> {
        return this.repository.find({
            where: { orderId },
            order: { createdAt: 'DESC' },
        });
    }

    async create(data: Partial<PaymentTransaction>): Promise<PaymentTransaction> {
        const transaction = this.repository.create(data);
        return this.repository.save(transaction);
    }
}
