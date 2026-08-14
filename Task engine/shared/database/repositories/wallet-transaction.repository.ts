import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { WalletTransaction } from '../entities/wallet-transaction.entity';

@Injectable()
export class WalletTransactionRepository {
    constructor(
        @InjectRepository(WalletTransaction)
        private readonly repo: Repository<WalletTransaction>,
    ) {}

    async findByWallet(walletId: string, limit: number = 20): Promise<WalletTransaction[]> {
        return this.repo.find({
            where: { walletId },
            order: { createdAt: 'DESC' },
            take: limit,
        });
    }

    async create(data: Partial<WalletTransaction>): Promise<WalletTransaction> {
        const txn = this.repo.create(data);
        return this.repo.save(txn);
    }
}
