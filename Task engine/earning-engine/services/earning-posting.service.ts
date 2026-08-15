import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { EarningRepository } from '../../shared/database/repositories/earning.repository';
import { Earning as EarningType } from '../types/earning';
import { Earning } from '../../shared/database/entities/earning.entity';
import { Worker } from '../../shared/database/entities/worker.entity';
import { Task } from '../../shared/database/entities/task.entity';
import { Order } from '../../shared/database/entities/order.entity';
import { Wallet } from '../../shared/database/entities/wallet.entity';
import { WalletTransaction } from '../../shared/database/entities/wallet-transaction.entity';

/**
 * Earning ko ledger me post karta hai safely with DB Transactions
 */
@Injectable()
export class EarningPostingService {
    constructor(
        private readonly dataSource: DataSource,
        private readonly earningRepo: EarningRepository,
    ) { }

    async post(earningData: EarningType): Promise<void> {
        await this.dataSource.transaction(async (manager) => {
            // Prevent duplicate earning posting for the same task with a lock
            const existingEarning = await manager.findOne(Earning, {
                where: { taskId: earningData.taskId },
                lock: { mode: 'pessimistic_write' },
            });
            
            if (existingEarning && existingEarning.status !== 'reversed') {
                console.log(`⚠️ Earning already posted for task ${earningData.taskId}. Skipping duplicate count.`);
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

            // Update worker stats
            let worker = await manager.findOne(Worker, { 
                where: { userId: earningData.workerId }, 
                lock: { mode: 'pessimistic_write' } 
            });
            if (!worker) {
                worker = await manager.findOne(Worker, { 
                    where: { id: earningData.workerId }, 
                    lock: { mode: 'pessimistic_write' } 
                });
            }

            if (worker) {
                worker.totalEarnings = Number(worker.totalEarnings || 0) + Number(earningData.amount || 0);
                worker.totalTasksCompleted = Number(worker.totalTasksCompleted || 0) + 1;
                
                const totalAttempts = worker.totalTasksCompleted + Number(worker.totalTasksRejected || 0);
                worker.successRate = totalAttempts > 0 ? (worker.totalTasksCompleted / totalAttempts) * 100 : 100;
                
                await manager.save(worker);
                
                // Credit to wallet — Use worker.userId (references User entity), NOT worker.id
                const walletUserId = worker.userId || worker.id;
                let wallet = await manager.findOne(Wallet, { 
                    where: { userId: walletUserId }, 
                    lock: { mode: 'pessimistic_write' } 
                });
                
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
            }

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

            console.log(`✅ Earning posted: ${created.id} - Amount: ${earningData.amount}`);
        });
    }

    async reverse(earningId: string): Promise<void> {
        const earning = await this.earningRepo.findById(earningId);
        if (!earning) {
            throw new Error('Earning not found');
        }

        await this.earningRepo.update(earningId, {
            status: 'reversed',
        });

        console.log(`↩️ Earning reversed: ${earningId}`);
    }
}
