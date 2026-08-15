import { Injectable } from '@nestjs/common';
import { EarningRepository } from '../../shared/database/repositories/earning.repository';
import { WorkerRepository } from '../../shared/database/repositories/worker.repository';
import { TaskRepository } from '../../shared/database/repositories/task.repository';
import { OrderRepository } from '../../shared/database/repositories/order.repository';
import { Earning } from '../types/earning';

import { WalletRepository } from '../../shared/database/repositories/wallet.repository';
import { WalletTransactionRepository } from '../../shared/database/repositories/wallet-transaction.repository';

/**
 * Earning ko ledger me post karta hai
 */
@Injectable()
export class EarningPostingService {
    constructor(
        private readonly earningRepo: EarningRepository,
        private readonly workerRepo: WorkerRepository,
        private readonly taskRepo: TaskRepository,
        private readonly orderRepo: OrderRepository,
        private readonly walletRepo: WalletRepository,
        private readonly walletTxRepo: WalletTransactionRepository,
    ) { }

    async post(earning: Earning): Promise<void> {
        // Prevent duplicate earning posting for the same task
        const existingEarning = await this.earningRepo.findByTaskId(earning.taskId);
        if (existingEarning && existingEarning.status !== 'reversed') {
            console.log(`⚠️ Earning already posted for task ${earning.taskId}. Skipping duplicate count.`);
            return;
        }

        // Create earning entry
        const created = await this.earningRepo.create({
            workerId: earning.workerId,
            taskId: earning.taskId,
            amount: earning.amount,
            type: earning.type,
            status: 'posted',
            metadata: earning.metadata,
        });

        // Update worker stats
        const worker = await this.workerRepo.findByUserId(earning.workerId) || await this.workerRepo.findById(earning.workerId);
        if (worker) {
            const newTotalEarnings = Number(worker.totalEarnings || 0) + Number(earning.amount || 0);
            const newCompletedCount = Number(worker.totalTasksCompleted || 0) + 1;
            const totalAttempts = newCompletedCount + Number(worker.totalTasksRejected || 0);
            const newSuccessRate = totalAttempts > 0 ? (newCompletedCount / totalAttempts) * 100 : 100;

            await this.workerRepo.update(worker.id, {
                totalEarnings: newTotalEarnings,
                totalTasksCompleted: newCompletedCount,
                successRate: newSuccessRate,
            });
            
            // Credit to wallet
            let wallet = await this.walletRepo.findByUserId(worker.id);
            if (!wallet) {
                wallet = await this.walletRepo.create(worker.id);
            }
            await this.walletRepo.updateBalance(wallet.id, earning.amount, true);
            await this.walletTxRepo.create({
                walletId: wallet.id,
                type: 'CREDIT',
                amount: earning.amount,
                description: `Earning for task ${earning.taskId}`,
                status: 'COMPLETED',
                referenceId: created.id,
            });
        }

        // Update order completed tasks count
        const task = await this.taskRepo.findById(earning.taskId);
        if (task && task.orderId) {
            // Atomic increment
            await this.orderRepo.incrementCompletedTasks(task.orderId);
            const order = await this.orderRepo.findById(task.orderId);
            if (order) {
                const isFinished = Number(order.tasksCompleted || 0) >= Number(order.totalTasksRequired);
                if (isFinished && order.status !== 'COMPLETED') {
                    await this.orderRepo.update(order.id, {
                        status: 'COMPLETED',
                    });
                }
            }
        }

        console.log(`✅ Earning posted: ${created.id} - Amount: ${earning.amount}`);
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
