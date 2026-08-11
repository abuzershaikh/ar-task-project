import { Injectable } from '@nestjs/common';
import { EarningRepository } from '../../shared/database/repositories/earning.repository';
import { WorkerRepository } from '../../shared/database/repositories/worker.repository';
import { TaskRepository } from '../../shared/database/repositories/task.repository';
import { OrderRepository } from '../../shared/database/repositories/order.repository';
import { Earning } from '../types/earning';

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
        }

        // Update order completed tasks count
        const task = await this.taskRepo.findById(earning.taskId);
        if (task && task.orderId) {
            const order = await this.orderRepo.findById(task.orderId);
            if (order) {
                const newCompleted = Number(order.tasksCompleted || 0) + 1;
                const isFinished = newCompleted >= Number(order.totalTasksRequired);
                await this.orderRepo.update(order.id, {
                    tasksCompleted: newCompleted,
                    status: isFinished ? 'completed' : order.status,
                });
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
