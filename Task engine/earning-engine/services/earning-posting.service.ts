import { Injectable, Logger } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { EarningRepository } from '../../shared/database/repositories/earning.repository';
import { Earning as EarningType } from '../types/earning';
import { Earning } from '../../shared/database/entities/earning.entity';
import { Worker } from '../../shared/database/entities/worker.entity';
import { User } from '../../shared/database/entities/user.entity';
import { Task } from '../../shared/database/entities/task.entity';
import { Order } from '../../shared/database/entities/order.entity';
import { Wallet } from '../../shared/database/entities/wallet.entity';
import { WalletTransaction } from '../../shared/database/entities/wallet-transaction.entity';

/**
 * Earning ko ledger me post aur reverse karta hai safely with DB Transactions & Wallet Integrity
 */
@Injectable()
export class EarningPostingService {
    private readonly logger = new Logger(EarningPostingService.name);

    constructor(
        private readonly dataSource: DataSource,
        private readonly earningRepo: EarningRepository,
        private readonly eventEmitter: EventEmitter2,
    ) { }

    async post(earningData: EarningType): Promise<void> {
        let resolvedWorkerId = earningData.workerId;

        await this.dataSource.transaction(async (manager) => {
            // Prevent duplicate earning posting for the same task with a lock
            const existingEarning = await manager.findOne(Earning, {
                where: { taskId: earningData.taskId },
                lock: { mode: 'pessimistic_write' },
            });

            if (existingEarning && existingEarning.status !== 'reversed') {
                this.logger.warn(`Earning already posted for task ${earningData.taskId}. Skipping duplicate.`);
                return;
            }

            // Create earning entry
            const earning = manager.create(Earning, {
                workerId: earningData.workerId,
                taskId: earningData.taskId,
                amount: earningData.amount,
                type: earningData.type,
                status: 'posted',
                metadata: earningData.metadata,
            });
            const created = await manager.save(earning);

            // Resolve User
            let user: User | null = null;
            try {
                user = await manager.findOne(User, {
                    where: { id: earningData.workerId },
                });
            } catch (_) {
                user = null;
            }

            // Update worker stats
            const workerLookup: any[] = [
                { userId: earningData.workerId },
                { id: earningData.workerId },
            ];
            if (user) {
                workerLookup.push({ userId: user.id });
                workerLookup.push({ id: user.id });
            }

            let worker = await manager.findOne(Worker, {
                where: workerLookup,
                lock: { mode: 'pessimistic_write' }
            }).catch(() => null);

            if (worker) {
                resolvedWorkerId = worker.id;
                worker.totalEarnings = Number(worker.totalEarnings || 0) + Number(earningData.amount || 0);
                worker.totalTasksCompleted = Number(worker.totalTasksCompleted || 0) + 1;

                const totalAttempts = worker.totalTasksCompleted + Number(worker.totalTasksRejected || 0);
                worker.successRate = totalAttempts > 0 ? (worker.totalTasksCompleted / totalAttempts) * 100 : 100;

                await manager.save(worker);
            }

            // Credit to wallet — Use worker.userId (references User entity) or user.id
            const walletUserId = user?.id || worker?.userId || worker?.id || earningData.workerId;
            let wallet = await manager.findOne(Wallet, {
                where: [{ userId: walletUserId }, { userId: earningData.workerId }],
                lock: { mode: 'pessimistic_write' }
            }).catch(() => null);

            if (!wallet) {
                wallet = manager.create(Wallet, { userId: walletUserId, availableBalance: 0, reservedBalance: 0 });
            }

            wallet.availableBalance = Number(wallet.availableBalance || 0) + Number(earningData.amount);
            await manager.save(wallet);

            const tx = manager.create(WalletTransaction, {
                walletId: wallet.id,
                type: 'CREDIT',
                amount: earningData.amount,
                description: `Earning for task ${earningData.taskId}`,
                status: 'COMPLETED',
                referenceId: created.id,
            });
            await manager.save(tx);

            // Update order completed tasks count
            const task = await manager.findOne(Task, { where: { id: earningData.taskId } });
            if (task && task.orderId) {
                const order = await manager.findOne(Order, {
                    where: { id: task.orderId },
                    lock: { mode: 'pessimistic_write' }
                });

                if (order) {
                    order.tasksCompleted = Number(order.tasksCompleted || 0) + 1;
                    const isFinished = order.tasksCompleted >= Number(order.totalTasksRequired);

                    if (isFinished && order.status !== 'COMPLETED') {
                        order.status = 'COMPLETED';
                    }
                    await manager.save(order);
                }
            }

            this.logger.log(`✅ Earning posted: ${created.id} - Amount: ${earningData.amount} for worker ${resolvedWorkerId}`);
        });

        // Trigger Realtime Score Recalculation & DB persistence
        this.eventEmitter.emit('worker.score.recalculate', resolvedWorkerId);
    }

    async reverse(earningId: string): Promise<void> {
        const earning = await this.earningRepo.findById(earningId);
        if (!earning) {
            throw new Error('Earning not found');
        }

        if (earning.status === 'reversed') {
            this.logger.warn(`Earning ${earningId} is already reversed`);
            return;
        }

        let resolvedWorkerId = earning.workerId;

        await this.dataSource.transaction(async (manager) => {
            // Mark earning as reversed
            earning.status = 'reversed';
            await manager.save(earning);

            // Resolve Worker
            let user: User | null = null;
            try {
                user = await manager.findOne(User, { where: { id: earning.workerId } });
            } catch (_) {}

            const workerLookup: any[] = [
                { userId: earning.workerId },
                { id: earning.workerId },
            ];
            if (user) {
                workerLookup.push({ userId: user.id });
                workerLookup.push({ id: user.id });
            }

            const worker = await manager.findOne(Worker, {
                where: workerLookup,
                lock: { mode: 'pessimistic_write' },
            }).catch(() => null);

            if (worker) {
                resolvedWorkerId = worker.id;
                // Allow totalEarnings to deduct even if it becomes negative or 0
                worker.totalEarnings = Number(worker.totalEarnings || 0) - Number(earning.amount || 0);
                worker.totalTasksCompleted = Math.max(0, Number(worker.totalTasksCompleted || 0) - 1);

                const totalAttempts = worker.totalTasksCompleted + Number(worker.totalTasksRejected || 0);
                worker.successRate = totalAttempts > 0 ? (worker.totalTasksCompleted / totalAttempts) * 100 : 0;

                await manager.save(worker);
            }

            // Debit Wallet - Allows negative balance if worker already withdrew funds
            const walletUserId = user?.id || worker?.userId || worker?.id || earning.workerId;
            const wallet = await manager.findOne(Wallet, {
                where: [{ userId: walletUserId }, { userId: earning.workerId }],
                lock: { mode: 'pessimistic_write' },
            }).catch(() => null);

            if (wallet) {
                // Negative balance allowed: future worker earnings will pay off negative deficit
                const currentBal = Number(wallet.availableBalance || 0);
                const deductAmount = Number(earning.amount || 0);
                const newBal = currentBal - deductAmount;
                wallet.availableBalance = newBal;
                await manager.save(wallet);

                const tx = manager.create(WalletTransaction, {
                    walletId: wallet.id,
                    type: 'DEBIT',
                    amount: earning.amount,
                    balanceAfter: newBal,
                    description: `Deduction / Penalty: Early app uninstall for task ${earning.taskId}`,
                    status: 'COMPLETED',
                    referenceId: earning.taskId || earning.id,
                });
                await manager.save(tx);
            }

            // Rollback Order tasksCompleted count if applicable
            const task = await manager.findOne(Task, { where: { id: earning.taskId } });
            if (task && task.orderId) {
                const order = await manager.findOne(Order, {
                    where: { id: task.orderId },
                    lock: { mode: 'pessimistic_write' },
                });

                if (order) {
                    order.tasksCompleted = Math.max(0, Number(order.tasksCompleted || 0) - 1);
                    if (order.status === 'COMPLETED') {
                        order.status = 'IN_PROGRESS';
                    }
                    await manager.save(order);
                }
            }

            this.logger.log(`↩️ Earning reversed atomically: ${earningId} - Amount: ${earning.amount}`);
        });

        // Trigger Score Recalculation after reversal
        this.eventEmitter.emit('worker.score.recalculate', resolvedWorkerId);
    }
}
