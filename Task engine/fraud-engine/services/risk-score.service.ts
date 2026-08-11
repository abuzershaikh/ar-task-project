import { Injectable } from '@nestjs/common';
import { WorkerRepository } from '../../shared/database/repositories/worker.repository';
import { TaskRepository } from '../../shared/database/repositories/task.repository';

/**
 * Worker ka risk score calculate karta hai
 */
@Injectable()
export class RiskScoreService {
    constructor(
        private readonly workerRepo: WorkerRepository,
        private readonly taskRepo: TaskRepository,
    ) { }

    async calculate(workerId: string, actionType: string): Promise<number> {
        const worker = await this.workerRepo.findById(workerId);
        if (!worker) {
            return 100; // Maximum risk for unknown worker
        }

        let riskScore = 0;

        // Factor 1: Rejection rate (max 30 points)
        const rejectionRate = this.calculateRejectionRate(worker);
        riskScore += rejectionRate * 30;

        // Factor 2: Account age (max 20 points)
        const accountAge = this.calculateAccountAge(worker);
        if (accountAge < 7) {
            riskScore += 20;
        } else if (accountAge < 30) {
            riskScore += 10;
        }

        // Factor 3: Success rate (max 25 points)
        const successRate = worker.successRate || 0;
        if (successRate < 50) {
            riskScore += 25;
        } else if (successRate < 70) {
            riskScore += 15;
        }

        // Factor 4: Recent activity (max 25 points)
        const recentRisk = await this.calculateRecentActivityRisk(workerId);
        riskScore += recentRisk;

        return Math.min(100, Math.round(riskScore));
    }

    private calculateRejectionRate(worker: any): number {
        const total = worker.totalTasksCompleted + worker.totalTasksRejected;
        if (total === 0) return 0;
        return worker.totalTasksRejected / total;
    }

    private calculateAccountAge(worker: any): number {
        const createdAt = new Date(worker.createdAt);
        const now = new Date();
        const diffDays = Math.floor((now.getTime() - createdAt.getTime()) / (1000 * 60 * 60 * 24));
        return diffDays;
    }

    private async calculateRecentActivityRisk(workerId: string): Promise<number> {
        // Check for suspicious patterns in recent tasks
        // TODO: Implement detailed pattern detection
        return 0;
    }
}
