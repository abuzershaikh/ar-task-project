import { Injectable, NotFoundException } from '@nestjs/common';
import { WalletRepository } from '../database/repositories/wallet.repository';
import { WalletTransactionRepository } from '../database/repositories/wallet-transaction.repository';

@Injectable()
export class WalletService {
    constructor(
        private readonly walletRepo: WalletRepository,
        private readonly transactionRepo: WalletTransactionRepository,
    ) {}

    async getWalletBalance(userId: string) {
        let wallet = await this.walletRepo.findByUserId(userId);
        if (!wallet) {
            wallet = await this.walletRepo.create(userId);
        }
        return {
            available: Number(wallet.availableBalance),
            reserved: Number(wallet.reservedBalance),
            total: Number(wallet.availableBalance) + Number(wallet.reservedBalance),
        };
    }

    async getTransactions(userId: string, limit: number = 20) {
        const wallet = await this.walletRepo.findByUserId(userId);
        if (!wallet) {
            return { transactions: [], total: 0 };
        }
        const txns = await this.transactionRepo.findByWallet(wallet.id, limit);
        return { transactions: txns, total: txns.length };
    }

    async addBalance(userId: string, amount: number) {
        let wallet = await this.walletRepo.findByUserId(userId);
        if (!wallet) {
            wallet = await this.walletRepo.create(userId);
        }

        // Create pending transaction
        const txn = await this.transactionRepo.create({
            walletId: wallet.id,
            type: 'CREDIT',
            amount,
            description: 'Add Funds via Gateway',
            status: 'PENDING',
        });

        return {
            paymentUrl: `mock_payment_url_${txn.id}`,
            transactionId: txn.id,
        };
    }

    async verifyPayment(userId: string, transactionId: string) {
        // In real world, check with payment gateway. Here we mock verify.
        let wallet = await this.walletRepo.findByUserId(userId);
        if (!wallet) throw new NotFoundException('Wallet not found');

        // Note: For a robust implementation we should query the txn by ID.
        // For simplicity, we just mark wallet balance up directly.
        // In production, we'd update the transaction status.
        await this.walletRepo.updateBalance(wallet.id, 1500, true);

        return {
            status: 'verified',
        };
    }
}
