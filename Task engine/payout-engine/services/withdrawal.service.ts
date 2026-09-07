import { Injectable, BadRequestException } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { EarningRepository } from '../../shared/database/repositories/earning.repository';
import { WithdrawalRepository } from '../../shared/database/repositories/withdrawal.repository';
import { WorkerRepository } from '../../shared/database/repositories/worker.repository';
import { PayoutConfigService } from './payout-config.service';
import { NotificationEngineService } from '../../notification-engine/notification.service';
import { Withdrawal, WithdrawalStatus } from '../../shared/database/entities/withdrawal.entity';
import { Worker } from '../../shared/database/entities/worker.entity';
import { Earning } from '../../shared/database/entities/earning.entity';
import { Wallet } from '../../shared/database/entities/wallet.entity';
import { WalletTransaction } from '../../shared/database/entities/wallet-transaction.entity';
import { PayoutRequest } from '../types';

/**
 * Withdrawal request create aur manage karta hai
 */
@Injectable()
export class WithdrawalService {
    constructor(
        private readonly dataSource: DataSource,
        private readonly earningRepo: EarningRepository,
        private readonly withdrawalRepo: WithdrawalRepository,
        private readonly workerRepo: WorkerRepository,
        private readonly configService: PayoutConfigService,
        private readonly notificationEngine: NotificationEngineService,
    ) { }

    async create(request: PayoutRequest): Promise<string> {
        return this.initiateWithdrawal(request);
    }

    async initiateWithdrawal(request: PayoutRequest): Promise<string> {
        const { workerId, amount, paymentMethod, idempotencyKey, metadata } = request;

        return this.dataSource.transaction(async (manager) => {
            // Idempotency check with lock
            if (idempotencyKey) {
                const existing = await manager.findOne(Withdrawal, {
                    where: { idempotencyKey },
                    lock: { mode: 'pessimistic_write' }
                });
                if (existing) {
                    return existing.id;
                }
            }

            // Acquire pessimistic lock on the Worker to serialize withdrawal requests
            let worker = await manager.findOne(Worker, { 
                where: [{ userId: workerId }, { id: workerId }],
                lock: { mode: 'pessimistic_write' },
                relations: ['profile']
            });

            // Canonical ID resolution for earnings & withdrawals (support both users.id and workers.id)
            const matchingWorkerIds = Array.from(new Set([workerId, worker?.id, worker?.userId].filter(Boolean) as string[]));

            const minLimit = worker?.profile?.minWithdrawalLimit || this.configService.getGlobalMinWithdrawalLimit();

            if (amount < minLimit) {
                throw new BadRequestException(
                    `Minimum withdrawal threshold is ₹${minLimit.toFixed(2)}. Your requested amount of ₹${amount.toFixed(2)} does not meet the minimum requirement.`,
                );
            }

            // Calculate available balance inside the transaction across all matching IDs
            const resultEarned = await manager.createQueryBuilder(Earning, 'earning')
                .select('SUM(earning.amount)', 'total')
                .where('earning.worker_id IN (:...matchingWorkerIds)', { matchingWorkerIds })
                .andWhere('earning.status = :status', { status: 'posted' })
                .getRawOne();
            const totalEarned = parseFloat(resultEarned?.total || 0);

            const resultDeducted = await manager.createQueryBuilder(Withdrawal, 'withdrawal')
                .select('SUM(withdrawal.amount)', 'total')
                .where('withdrawal.worker_id IN (:...matchingWorkerIds)', { matchingWorkerIds })
                .andWhere('withdrawal.status IN (:...statuses)', { 
                    statuses: [
                        WithdrawalStatus.REQUESTED,
                        WithdrawalStatus.UNDER_REVIEW,
                        WithdrawalStatus.PROCESSING,
                        WithdrawalStatus.PAID,
                    ] 
                })
                .getRawOne();
            const totalDeducted = parseFloat(resultDeducted?.total || 0);

            const availableBalance = Math.max(0, totalEarned - totalDeducted);

            if (amount > availableBalance) {
                throw new BadRequestException(
                    `Insufficient balance. Available: ₹${availableBalance.toFixed(2)}, Requested: ₹${amount.toFixed(2)}`,
                );
            }

            // Save withdrawal with workerId matching the user/worker
            const withdrawalEntity = manager.create(Withdrawal, {
                workerId: workerId,
                amount,
                status: WithdrawalStatus.REQUESTED,
                paymentMethodId: paymentMethod || 'DEFAULT',
                requestedAt: new Date(),
                idempotencyKey,
                metadata,
            });

            const withdrawal = await manager.save(withdrawalEntity);

            // Synchronize with wallets table: reserve the balance so parallel withdrawal / order is blocked
            const walletUserId = worker?.userId || workerId;
            let wallet = await manager.findOne(Wallet, {
                where: [{ userId: walletUserId }, { userId: workerId }],
                lock: { mode: 'pessimistic_write' },
            });
            if (wallet) {
                const currentAvail = Number(wallet.availableBalance || 0);
                wallet.availableBalance = Math.max(0, currentAvail - amount);
                wallet.reservedBalance = Number(wallet.reservedBalance || 0) + amount;
                await manager.save(wallet);

                const tx = manager.create(WalletTransaction, {
                    walletId: wallet.id,
                    type: 'DEBIT',
                    amount,
                    balanceAfter: wallet.availableBalance,
                    description: `Withdrawal request #${withdrawal.id.slice(0, 8)}`,
                    status: 'PENDING',
                    referenceId: withdrawal.id,
                });
                await manager.save(tx);
            }

            await this.notificationEngine.sendNotification(
                workerId,
                `Withdrawal request for ₹${amount.toFixed(2)} submitted successfully. Status: Pending processing.`,
                'PAYOUT_REQUESTED',
                { withdrawalId: withdrawal.id, amount }
            );

            console.log(`💰 Withdrawal initiated: ${withdrawal.id} - ₹${amount} (Min Limit: ₹${minLimit})`);
            return withdrawal.id;
        });
    }

    async getBalance(workerId: string): Promise<number> {
        const worker = await this.workerRepo.findWorker(workerId);
        const matchingWorkerIds = Array.from(new Set([workerId, worker?.id, worker?.userId].filter(Boolean) as string[]));

        const totalEarned = await this.earningRepo.getTotalEarnings(matchingWorkerIds);
        const totalDeducted = await this.withdrawalRepo.getTotalWithdrawalsAmount(matchingWorkerIds, [
            WithdrawalStatus.REQUESTED,
            WithdrawalStatus.UNDER_REVIEW,
            WithdrawalStatus.PROCESSING,
            WithdrawalStatus.PAID,
        ]);

        return Math.max(0, totalEarned - totalDeducted);
    }
}
