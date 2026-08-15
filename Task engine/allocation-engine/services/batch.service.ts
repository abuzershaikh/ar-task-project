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
        const pendingTasks = tasks.filter(t => this.taskRepo.matchesStatus(t.status, 'pending'));

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

            // Build explicit pairs for tasks with matched workers
            const pairs: Array<{ taskId: string; workerId: string }> = [];
            const matchedTaskIds: string[] = [];

            for (const taskId of taskIds) {
                const match = matchingResults.get(taskId);
                if (match && match.matchedWorkers.length > 0) {
                    pairs.push({
                        taskId,
                        workerId: match.matchedWorkers[0].workerId,
                    });
                    matchedTaskIds.push(taskId);
                } else {
                    // Update task retry metadata for unmatched task
                    const currentMetadata = batch.find(t => t.id === taskId)?.metadata || {};
                    const noMatchCount = (currentMetadata.noMatchCount || 0) + 1;
                    
                    if (noMatchCount >= 3) {
                        console.error(`🚨 Task ${taskId} exceeded max no-match retries (3). Marking as FAILED.`);
                        await this.taskRepo.update(taskId, {
                            status: 'failed' as any, // or TaskStatus.FAILED
                            metadata: {
                                ...currentMetadata,
                                lastMatchAttemptAt: new Date().toISOString(),
                                noMatchCount,
                                failureReason: 'No eligible candidates found after 3 attempts',
                            },
                        });
                    } else {
                        await this.taskRepo.update(taskId, {
                            metadata: {
                                ...currentMetadata,
                                lastMatchAttemptAt: new Date().toISOString(),
                                noMatchCount,
                            },
                        });
                        console.warn(`⚠️ Task ${taskId} has no matched candidates in batch ${batchNumber}`);
                        // Push a dummy failed result for this unmatched task so it triggers a batch retry
                        results.push({
                            assignments: [],
                            successCount: 0,
                            failedCount: 1,
                            timestamp: new Date(),
                        });
                    }
                }
            }

            if (pairs.length > 0) {
                const result = await this.assignmentService.assign({
                    taskIds: matchedTaskIds,
                    workerIds: pairs.map(p => p.workerId),
                    pairs,
                    strategy: 'sequential',
                });
                results.push(result);
            }
        }

        return results;
    }
}
