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

    async findByWallet(
        walletId: string,
        type?: string,
        page: number = 1,
        limit: number = 20,
    ): Promise<{ transactions: WalletTransaction[]; total: number }> {
        const query = this.repo.createQueryBuilder('txn')
            .where('txn.walletId = :walletId', { walletId });

        if (type && type.trim().toLowerCase() !== 'all') {
            const upperType = type.trim().toUpperCase();
            if (upperType === 'CREDIT' || upperType === 'CREDITS') {
                query.andWhere('UPPER(txn.type) IN (:...creditTypes)', {
                    creditTypes: ['CREDIT', 'REFUND', 'RELEASE', 'RELEASED'],
                });
            } else if (upperType === 'DEBIT' || upperType === 'DEBITS') {
                query.andWhere('UPPER(txn.type) IN (:...debitTypes)', {
                    debitTypes: ['DEBIT', 'CAPTURED', 'CAPTURE'],
                });
            } else if (upperType === 'RESERVED' || upperType === 'RESERVE') {
                query.andWhere('UPPER(txn.type) IN (:...reservedTypes)', {
                    reservedTypes: ['RESERVED', 'RESERVE', 'HOLD'],
                });
            } else {
                query.andWhere('UPPER(txn.type) = :type', { type: upperType });
            }
        }

        const safePage = Math.max(1, page || 1);
        const safeLimit = Math.max(1, limit || 20);

        const [transactions, total] = await query
            .orderBy('txn.createdAt', 'DESC')
            .skip((safePage - 1) * safeLimit)
            .take(safeLimit)
            .getManyAndCount();

        return { transactions, total };
    }

    async create(data: Partial<WalletTransaction>): Promise<WalletTransaction> {
        const txn = this.repo.create(data);
        return this.repo.save(txn);
    }
}
