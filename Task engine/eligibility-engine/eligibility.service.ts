import { Injectable } from '@nestjs/common';
import { EligibilityResult } from './types/eligibility-result';

import { WorkerRepository } from '../shared/database/repositories/worker.repository';
import { TaskRepository } from '../shared/database/repositories/task.repository';

/**
 * Eligibility Engine
 * Worker task ke liye eligible hai ya nahi check karta hai
 */
@Injectable()
export class EligibilityEngineService {
    constructor(
        private readonly workerRepo: WorkerRepository,
        private readonly taskRepo: TaskRepository,
    ) { }

    async checkEligibility(
        workerId: string,
        taskId: string,
    ): Promise<EligibilityResult> {
        const reasons: string[] = [];
        let isEligible = true;

        if (!workerId || typeof workerId !== 'string') {
            return { isEligible: false, reasons: ['Invalid worker ID'], rules: {} };
        }

        if (!taskId || typeof taskId !== 'string') {
            return { isEligible: false, reasons: ['Invalid task ID'], rules: {} };
        }

        const [worker, task] = await Promise.all([
            this.workerRepo.findById(workerId),
            this.taskRepo.findById(taskId)
        ]);

        if (!worker) {
            isEligible = false;
            reasons.push('Worker not found');
        } else if (worker.status !== 'active') {
            isEligible = false;
            reasons.push('Worker is not active');
        }

        if (!task) {
            isEligible = false;
            reasons.push('Task not found');
        } else if (task.status !== 'active') {
            isEligible = false;
            reasons.push('Task is not active');
        }

        return {
            isEligible,
            reasons,
            rules: {
                workerActive: worker?.status === 'active',
                taskActive: task?.status === 'active',
            },
        };
    }

    async batchCheckEligibility(
        workerIds: string[],
        taskId: string,
    ): Promise<Map<string, EligibilityResult>> {
        const results = new Map<string, EligibilityResult>();

        if (!workerIds || workerIds.length === 0) return results;

        // Fetch task once for batch
        const task = await this.taskRepo.findById(taskId);
        if (!task || task.status !== 'active') {
             for (const id of workerIds) {
                 results.set(id, { isEligible: false, reasons: ['Task not active or found'], rules: {} });
             }
             return results;
        }

        // Fetch workers in bulk
        const workers = await this.workerRepo.findByIds(workerIds);

        for (const workerId of workerIds) {
            const worker = workers.find(w => w.id === workerId);
            if (!worker || worker.status !== 'active') {
                results.set(workerId, {
                    isEligible: false,
                    reasons: ['Worker not found or not active'],
                    rules: { workerActive: false }
                });
            } else {
                results.set(workerId, {
                    isEligible: true,
                    reasons: [],
                    rules: { workerActive: true, taskActive: true }
                });
            }
        }

        return results;
    }
}
