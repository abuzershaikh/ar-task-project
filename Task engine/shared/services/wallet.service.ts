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

    async getTransactions(userId: string, type?: string, page: number = 1, limit: number = 20) {
        const wallet = await this.getOrCreateWallet(userId);
        const { transactions, total } = await this.transactionRepo.findByWallet(wallet.id, type, page, limit);
        return { transactions, total };
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
            .createQueryBuilder(User, 'u');

        if (search && search.trim().length > 0) {
            const term = `%${search.trim().toLowerCase()}%`;
            query = query.where(
                '(LOWER(u.fullName) LIKE :term OR LOWER(u.email) LIKE :term OR u.phone LIKE :term OR u.id LIKE :term)',
                { term },
            );
        } else {
            query = query.where(
                '(u.role = :buyerRole OR u.role = :superRole OR u.id IN (SELECT DISTINCT o.buyer_id FROM orders o WHERE o.buyer_id IS NOT NULL))',
                {
                    buyerRole: UserRole.BUYER,
                    superRole: UserRole.SUPER_ADMIN,
                },
            );
        }

        const buyers = await query.orderBy('u.createdAt', 'DESC').getMany();

        const results = await Promise.all(
            buyers.map(async (buyer) => {
                const wallet = await this.getOrCreateWallet(buyer.id);
                return {
                    id: buyer.id,
                    fullName: buyer.fullName || buyer.email.split('@')[0],
                    email: buyer.email,
                    avatarUrl: buyer.avatarUrl || null,
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
        const { transactions, total } = await this.transactionRepo.findByWallet(wallet.id, undefined, 1, limit);
        return {
            success: true,
            buyerId,
            availableBalance: Number(wallet.availableBalance),
            transactions,
            total,
        };
    }

    /**
     * Admin: Get all buyer topup purchase history (Razorpay + Admin additions)
     */
    async getBuyerTopupHistory(options?: {
        filter?: 'ALL' | 'RAZORPAY' | 'ADMIN';
        search?: string;
        limit?: number;
    }) {
        const filter = options?.filter || 'ALL';
        const search = options?.search?.trim();

        // 1. Calculate overall summary
        const summaryRaw = await this.dataSource.query(`
            SELECT 
                COALESCE(SUM(wt.amount), 0) as totalTopupAmount,
                COALESCE(SUM(CASE WHEN wt.description LIKE '%Razorpay%' THEN wt.amount ELSE 0 END), 0) as totalRazorpayAmount,
                COALESCE(SUM(CASE WHEN wt.description NOT LIKE '%Razorpay%' THEN wt.amount ELSE 0 END), 0) as totalAdminAmount,
                COUNT(*) as totalCount,
                COALESCE(SUM(CASE WHEN wt.description LIKE '%Razorpay%' THEN 1 ELSE 0 END), 0) as razorpayCount,
                COALESCE(SUM(CASE WHEN wt.description NOT LIKE '%Razorpay%' THEN 1 ELSE 0 END), 0) as adminCount
            FROM wallet_transactions wt
            JOIN wallets w ON wt.wallet_id = w.id
            JOIN users u ON w.user_id = u.id
            WHERE wt.type = 'CREDIT' 
              AND (wt.description LIKE '%Razorpay%' OR wt.description LIKE '%Admin%' OR wt.description LIKE '%Top-up%' OR wt.description LIKE '%Topup%');
        `);

        const summary = {
            totalTopupAmount: Number(summaryRaw[0]?.totalTopupAmount || 0),
            totalRazorpayAmount: Number(summaryRaw[0]?.totalRazorpayAmount || 0),
            totalAdminAmount: Number(summaryRaw[0]?.totalAdminAmount || 0),
            totalCount: Number(summaryRaw[0]?.totalCount || 0),
            razorpayCount: Number(summaryRaw[0]?.razorpayCount || 0),
            adminCount: Number(summaryRaw[0]?.adminCount || 0),
        };

        // 2. Build list query with filtering and search
        const whereClauses: string[] = [
            "wt.type = 'CREDIT'",
            "(wt.description LIKE '%Razorpay%' OR wt.description LIKE '%Admin%' OR wt.description LIKE '%Top-up%' OR wt.description LIKE '%Topup%')"
        ];
        const params: any[] = [];

        if (filter === 'RAZORPAY') {
            whereClauses.push("wt.description LIKE '%Razorpay%'");
        } else if (filter === 'ADMIN') {
            whereClauses.push("wt.description NOT LIKE '%Razorpay%'");
        }

        if (search && search.length > 0) {
            const term = `%${search.toLowerCase()}%`;
            whereClauses.push("(LOWER(u.full_name) LIKE ? OR LOWER(u.email) LIKE ? OR LOWER(wt.description) LIKE ? OR u.phone LIKE ? OR wt.id LIKE ?)");
            params.push(term, term, term, term, term);
        }

        const whereSql = `WHERE ${whereClauses.join(' AND ')}`;

        const sql = `
            SELECT 
                wt.id, 
                wt.amount, 
                wt.balance_after as balanceAfter, 
                wt.description, 
                wt.status,
                DATE_FORMAT(wt.created_at, '%Y-%m-%d %H:%i:%s') as createdAt, 
                u.id as userId, 
                u.full_name as fullName, 
                u.email, 
                u.phone, 
                u.avatar_url as avatarUrl, 
                u.role
            FROM wallet_transactions wt
            JOIN wallets w ON wt.wallet_id = w.id
            JOIN users u ON w.user_id = u.id
            ${whereSql}
            ORDER BY wt.created_at DESC
        `;

        const rawList = await this.dataSource.query(sql, params);

        const transactions = rawList.map((item: any) => {
            const isRazorpay = typeof item.description === 'string' && item.description.includes('Razorpay');
            let paymentId: string | null = null;
            if (isRazorpay) {
                const match = item.description.match(/pay_[A-Za-z0-9]+/);
                if (match) {
                    paymentId = match[0];
                }
            }

            return {
                id: item.id,
                amount: Number(item.amount),
                balanceAfter: Number(item.balanceAfter),
                method: isRazorpay ? 'RAZORPAY' : 'ADMIN',
                source: isRazorpay ? 'RAZORPAY' : 'ADMIN',
                paymentId,
                description: item.description,
                status: item.status || 'COMPLETED',
                createdAt: item.createdAt,
                buyer: {
                    id: item.userId,
                    fullName: item.fullName || (item.email ? item.email.split('@')[0] : 'Buyer'),
                    email: item.email,
                    phone: item.phone,
                    avatarUrl: item.avatarUrl,
                    role: item.role,
                },
            };
        });

        return {
            success: true,
            summary,
            transactions,
            total: transactions.length,
        };
    }
}

