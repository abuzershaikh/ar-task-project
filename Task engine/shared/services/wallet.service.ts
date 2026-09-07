import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { WalletRepository } from '../database/repositories/wallet.repository';
import { WalletTransactionRepository } from '../database/repositories/wallet-transaction.repository';
import { UserRepository } from '../database/repositories/user.repository';
import { User, UserRole } from '../database/entities/user.entity';
import { Wallet } from '../database/entities/wallet.entity';
import { WalletTransaction } from '../database/entities/wallet-transaction.entity';

@Injectable()
export class WalletService {
    constructor(
        private readonly walletRepo: WalletRepository,
        private readonly transactionRepo: WalletTransactionRepository,
        private readonly userRepo: UserRepository,
        private readonly dataSource: DataSource,
    ) {}

    /**
     * Get or initialize wallet for a user.
     * Default initial balance is 0.00. Admin adds balance via Admin App Top-Up.
     */
    async getOrCreateWallet(userId: string) {
        let wallet = await this.walletRepo.findByUserId(userId);
        if (!wallet) {
            wallet = await this.walletRepo.create(userId, 0.00);
        }
        return wallet;
    }

    async getWalletBalance(userId: string) {
        const wallet = await this.getOrCreateWallet(userId);
        return {
            available: Number(wallet.availableBalance),
            reserved: Number(wallet.reservedBalance),
            total: Number(wallet.availableBalance) + Number(wallet.reservedBalance),
        };
    }

    async getTransactions(userId: string, limit: number = 50) {
        const wallet = await this.getOrCreateWallet(userId);
        const txns = await this.transactionRepo.findByWallet(wallet.id, limit);
        return { transactions: txns, total: txns.length };
    }

    /**
     * Deduct funds for campaign order placement.
     * Throws BadRequestException if insufficient balance.
     */
    async deductForOrder(userId: string, amount: number, orderId: string, orderTitle?: string) {
        return this.dataSource.transaction(async (manager) => {
            let wallet = await manager.findOne(Wallet, {
                where: { userId },
                lock: { mode: 'pessimistic_write' },
            });
            if (!wallet) {
                wallet = manager.create(Wallet, { userId, availableBalance: 0, reservedBalance: 0 });
                await manager.save(wallet);
            }

            const currentBalance = Number(wallet.availableBalance);
            if (currentBalance < amount) {
                throw new BadRequestException(
                    `Insufficient wallet balance. Required: ₹${amount.toFixed(2)}, Available: ₹${currentBalance.toFixed(2)}. Please top up your wallet.`,
                );
            }

            const remainingBalance = currentBalance - amount;
            wallet.availableBalance = remainingBalance;
            await manager.save(wallet);

            const txn = manager.create(WalletTransaction, {
                walletId: wallet.id,
                type: 'DEBIT',
                amount,
                balanceAfter: remainingBalance,
                referenceId: orderId,
                description: orderTitle ? `Campaign Order: ${orderTitle}` : `Campaign Order #${orderId.slice(0, 8)}`,
                status: 'COMPLETED',
            });
            const savedTxn = await manager.save(txn);

            return {
                success: true,
                deductedAmount: amount,
                remainingBalance,
                transactionId: savedTxn.id,
            };
        });
    }

    /**
     * Top-up balance (Buyer self-topup or simulation)
     */
    async topupBalance(userId: string, amount: number, description: string = 'Wallet Top-up') {
        if (amount <= 0) {
            throw new BadRequestException('Topup amount must be greater than 0');
        }

        return this.dataSource.transaction(async (manager) => {
            let wallet = await manager.findOne(Wallet, {
                where: { userId },
                lock: { mode: 'pessimistic_write' },
            });
            if (!wallet) {
                wallet = manager.create(Wallet, { userId, availableBalance: 0, reservedBalance: 0 });
                await manager.save(wallet);
            }

            const currentBalance = Number(wallet.availableBalance);
            const newBalance = currentBalance + amount;
            wallet.availableBalance = newBalance;
            await manager.save(wallet);

            const txn = manager.create(WalletTransaction, {
                walletId: wallet.id,
                type: 'CREDIT',
                amount,
                balanceAfter: newBalance,
                description,
                status: 'COMPLETED',
            });
            const savedTxn = await manager.save(txn);

            return {
                success: true,
                addedAmount: amount,
                newBalance,
                transaction: savedTxn,
            };
        });
    }

    /**
     * Admin Top-Up or Debit for any buyer
     */
    async adminTopup(
        buyerId: string,
        amount: number,
        type: 'CREDIT' | 'DEBIT' = 'CREDIT',
        notes?: string,
    ) {
        if (amount <= 0) {
            throw new BadRequestException('Amount must be greater than 0');
        }

        return this.dataSource.transaction(async (manager) => {
            const user = await manager.findOne(User, { where: { id: buyerId } });
            if (!user) {
                throw new NotFoundException(`User with ID '${buyerId}' not found`);
            }
            if (user.role !== UserRole.BUYER && user.role !== UserRole.ADMIN && user.role !== UserRole.SUPER_ADMIN) {
                throw new BadRequestException(`User '${buyerId}' is not a buyer or admin (Role: ${user.role})`);
            }

            let wallet = await manager.findOne(Wallet, {
                where: { userId: buyerId },
                lock: { mode: 'pessimistic_write' },
            });
            if (!wallet) {
                wallet = manager.create(Wallet, { userId: buyerId, availableBalance: 0, reservedBalance: 0 });
                await manager.save(wallet);
            }

            const currentBalance = Number(wallet.availableBalance);

            if (type === 'DEBIT' && currentBalance < amount) {
                throw new BadRequestException(
                    `Cannot debit ₹${amount.toFixed(2)}. Buyer currently only has ₹${currentBalance.toFixed(2)} available.`,
                );
            }

            const newBalance = type === 'CREDIT' ? currentBalance + amount : currentBalance - amount;
            wallet.availableBalance = newBalance;
            await manager.save(wallet);

            const txn = manager.create(WalletTransaction, {
                walletId: wallet.id,
                type,
                amount,
                balanceAfter: newBalance,
                description: notes || `Admin Manual ${type === 'CREDIT' ? 'Credit' : 'Debit'}`,
                status: 'COMPLETED',
            });
            const savedTxn = await manager.save(txn);

            return {
                success: true,
                buyerId,
                type,
                amount,
                previousBalance: currentBalance,
                newBalance,
                transaction: savedTxn,
            };
        });
    }

    /**
     * Admin: Get all buyers along with their live wallet balances and stats
     */
    async getAllBuyersWithWallet(search?: string) {
        let query = this.dataSource
            .createQueryBuilder(User, 'u')
            .where('u.role = :buyerRole OR u.role = :superRole', {
                buyerRole: UserRole.BUYER,
                superRole: UserRole.SUPER_ADMIN,
            });

        if (search && search.trim().length > 0) {
            const term = `%${search.trim().toLowerCase()}%`;
            query = query.andWhere(
                '(LOWER(u.fullName) LIKE :term OR LOWER(u.email) LIKE :term OR u.id LIKE :term)',
                { term },
            );
        }

        const buyers = await query.getMany();

        const results = await Promise.all(
            buyers.map(async (buyer) => {
                const wallet = await this.getOrCreateWallet(buyer.id);
                return {
                    id: buyer.id,
                    fullName: buyer.fullName || buyer.email.split('@')[0],
                    email: buyer.email,
                    phone: buyer.phone,
                    role: buyer.role,
                    status: buyer.status,
                    createdAt: buyer.createdAt,
                    wallet: {
                        id: wallet.id,
                        availableBalance: Number(wallet.availableBalance),
                        reservedBalance: Number(wallet.reservedBalance),
                        totalBalance: Number(wallet.availableBalance) + Number(wallet.reservedBalance),
                    },
                };
            }),
        );

        return {
            success: true,
            buyers: results,
            total: results.length,
        };
    }

    /**
     * Admin: Get transactions for a specific buyer
     */
    async getBuyerTransactions(buyerId: string, limit: number = 50) {
        const wallet = await this.getOrCreateWallet(buyerId);
        const transactions = await this.transactionRepo.findByWallet(wallet.id, limit);
        return {
            success: true,
            buyerId,
            availableBalance: Number(wallet.availableBalance),
            transactions,
            total: transactions.length,
        };
    }
}
