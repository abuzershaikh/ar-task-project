import { Injectable } from '@nestjs/common';
import { TaskRepository } from '../../shared/database/repositories/task.repository';
import { EarningRepository } from '../../shared/database/repositories/earning.repository';
import { WorkerRepository } from '../../shared/database/repositories/worker.repository';

/**
 * Worker ka progress aur stats track karta hai
 */
@Injectable()
export class WorkerProgressService {
    constructor(
        private readonly taskRepo: TaskRepository,
        private readonly earningRepo: EarningRepository,
        private readonly workerRepo: WorkerRepository,
    ) { }

    async getProgress(workerId: string) {
        const worker = await this.workerRepo.findById(workerId);
        if (!worker) {
            throw new Error('Worker not found');
        }

        const tasks = await this.taskRepo.findByWorker(workerId);
        const totalEarnings = await this.earningRepo.getTotalEarnings(workerId);

        const assigned = tasks.filter(t => t.status === 'assigned').length;
        const inProgress = tasks.filter(t => ['accepted', 'in_progress'].includes(t.status)).length;
        const submitted = tasks.filter(t => t.status === 'submitted').length;
        const completed = tasks.filter(t => t.status === 'completed').length;
        const rejected = tasks.filter(t => t.status === 'rejected').length;

        const total = tasks.length;
        const successRate = total > 0 ? (completed / (completed + rejected)) * 100 : 0;

        return {
            workerId,
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
                available: totalEarnings, // TODO: Subtract withdrawals
                pending: 0,
            },
            stats: {
                successRate: Math.round(successRate * 100) / 100,
                averageRating: worker.averageRating,
                totalCompleted: worker.totalTasksCompleted,
            },
        };
    }
}
