import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Wallet } from '../entities/wallet.entity';

@Injectable()
export class WalletRepository {
    constructor(
        @InjectRepository(Wallet)
        private readonly repo: Repository<Wallet>,
    ) {}

    async findByUserId(userId: string): Promise<Wallet | null> {
        return this.repo.findOne({ where: { userId } });
    }

    async create(userId: string, initialBalance: number = 0.00): Promise<Wallet> {
        const wallet = this.repo.create({
            userId,
            availableBalance: initialBalance,
            reservedBalance: 0,
        });
        return this.repo.save(wallet);
    }

    async updateBalance(walletId: string, amount: number, isAvailable: boolean = true): Promise<void> {
        if (isAvailable) {
            await this.repo.increment({ id: walletId }, 'availableBalance', amount);
        } else {
            await this.repo.increment({ id: walletId }, 'reservedBalance', amount);
        }
    }

    async deductBalance(walletId: string, amount: number): Promise<void> {
        await this.repo.decrement({ id: walletId }, 'availableBalance', amount);
    }

    async setBalance(walletId: string, availableBalance: number): Promise<void> {
        await this.repo.update({ id: walletId }, { availableBalance });
    }
}
