import { Injectable } from '@nestjs/common';
import { TaskRepository } from '../../shared/database/repositories/task.repository';
import { EarningRepository } from '../../shared/database/repositories/earning.repository';
import { WorkerRepository } from '../../shared/database/repositories/worker.repository';
import { WithdrawalRepository } from '../../shared/database/repositories/withdrawal.repository';
import { WithdrawalStatus } from '../../shared/database/entities/withdrawal.entity';

/**
 * Worker ka progress aur stats track karta hai
 */
@Injectable()
export class WorkerProgressService {
    constructor(
        private readonly taskRepo: TaskRepository,
        private readonly earningRepo: EarningRepository,
        private readonly workerRepo: WorkerRepository,
        private readonly withdrawalRepo: WithdrawalRepository,
    ) { }

    async getProgress(workerId: string) {
        const worker = await this.workerRepo.findById(workerId) || await this.workerRepo.findByUserId(workerId);
        if (!worker) {
            throw new Error('Worker not found');
        }

        const matchingWorkerIds = Array.from(new Set([workerId, worker.id, worker.userId].filter(Boolean) as string[]));

        const tasks = await this.taskRepo.findByWorker(worker.id);
        const totalEarnings = await this.earningRepo.getTotalEarnings(matchingWorkerIds);
        const totalDeducted = await this.withdrawalRepo.getTotalWithdrawalsAmount(matchingWorkerIds, [
            WithdrawalStatus.REQUESTED,
            WithdrawalStatus.UNDER_REVIEW,
            WithdrawalStatus.PROCESSING,
            WithdrawalStatus.PAID,
        ]);
        const pendingWithdrawals = await this.withdrawalRepo.getTotalWithdrawalsAmount(matchingWorkerIds, [
            WithdrawalStatus.REQUESTED,
            WithdrawalStatus.UNDER_REVIEW,
            WithdrawalStatus.PROCESSING,
        ]);
        const availableEarnings = Math.max(0, totalEarnings - totalDeducted);

        const assigned = tasks.filter(t => t.status === 'assigned').length;
        const inProgress = tasks.filter(t => ['accepted', 'in_progress'].includes(t.status)).length;
        const submitted = tasks.filter(t => t.status === 'submitted').length;
        const completed = tasks.filter(t => t.status === 'completed').length;
        const rejected = tasks.filter(t => t.status === 'rejected').length;

        const total = tasks.length;
        const successRate = total > 0 ? (completed / (completed + rejected)) * 100 : 0;

        return {
            workerId: worker.id,
            userId: worker.userId,
            tasks: {
                assigned,
                inProgress,
                submitted,
                completed,
                rejected,
                total,
            },
            earnings: {
                total: totalEarnings,
                available: availableEarnings,
                pending: pendingWithdrawals,
            },
            stats: {
                successRate: Math.round(successRate * 100) / 100,
                averageRating: worker.averageRating,
                totalCompleted: worker.totalTasksCompleted,
            },
        };
    }
}

