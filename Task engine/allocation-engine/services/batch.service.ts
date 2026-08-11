import { Injectable } from '@nestjs/common';
import { TaskRepository } from '../../shared/database/repositories/task.repository';
import { MatchingEngineService } from '../../matching-engine/matching-engine.service';
import { AssignmentService } from './assignment.service';
import { AllocationResult } from '../types';

/**
 * Large orders ko batches mein process karta hai
 */
@Injectable()
export class BatchService {
    constructor(
        private readonly taskRepo: TaskRepository,
        private readonly matchingEngine: MatchingEngineService,
        private readonly assignmentService: AssignmentService,
    ) { }

    async processBatches(
        orderId: string,
        batchSize: number,
    ): Promise<AllocationResult[]> {
        // Get all pending tasks for this order
        const tasks = await this.taskRepo.findByOrderId(orderId);
        const pendingTasks = tasks.filter(t => t.status === 'pending');

        console.log(`📦 Processing ${pendingTasks.length} tasks in batches of ${batchSize}`);

        const results: AllocationResult[] = [];

        // Process in batches
        for (let i = 0; i < pendingTasks.length; i += batchSize) {
            const batch = pendingTasks.slice(i, i + batchSize);
            const batchNumber = Math.floor(i / batchSize) + 1;

            console.log(`🔄 Processing batch ${batchNumber}...`);

            // Match workers for this batch
            const taskIds = batch.map(t => t.id);
            const matchingResults = await this.matchingEngine.matchWorkersForBatch(taskIds);

            // Assign tasks
            const workerIds: string[] = [];
            taskIds.forEach(taskId => {
                const match = matchingResults.get(taskId);
                if (match && match.matchedWorkers.length > 0) {
                    workerIds.push(match.matchedWorkers[0].workerId);
                }
            });

            const result = await this.assignmentService.assign({
                taskIds,
                workerIds,
                strategy: 'sequential',
            });

            results.push(result);
        }

        return results;
    }
}
