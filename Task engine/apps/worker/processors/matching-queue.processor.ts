import { Processor, Process } from '@nestjs/bull';
import { Job } from 'bull';
import { Injectable } from '@nestjs/common';
import { MatchingEngineService } from '../../../matching-engine/matching-engine.service';
import { AllocationEngineService } from '../../../allocation-engine/allocation.service';

/**
 * Matching queue processor
 * Workers ko tasks match karta hai
 */
@Processor('matching')
@Injectable()
export class MatchingQueueProcessor {
    constructor(
        private readonly matchingEngine: MatchingEngineService,
        private readonly allocationEngine: AllocationEngineService,
    ) { }

    @Process('match-workers')
    async handleMatchWorkers(job: Job) {
        const { taskId } = job.data;

        console.log(`🎯 Matching workers for task ${taskId}`);

        try {
            // Match workers
            const result = await this.matchingEngine.matchWorkersForTask({ taskId });

            console.log(`✅ Found ${result.matchedWorkers.length} matching workers`);

            if (result.matchedWorkers.length > 0) {
                // Allocate to top worker
                const topWorker = result.matchedWorkers[0];

                await this.allocationEngine.allocateTasks({
                    taskIds: [taskId],
                    workerIds: [topWorker.workerId],
                    strategy: 'sequential',
                });

                console.log(`✅ Task ${taskId} allocated to worker ${topWorker.workerId}`);
            }

            return { success: true, matchedCount: result.matchedWorkers.length };
        } catch (error) {
            console.error('Failed to match workers:', error);
            throw error;
        }
    }

    @Process('batch-match')
    async handleBatchMatch(job: Job) {
        const { orderId, batchSize } = job.data;

        console.log(`📦 Batch matching for order ${orderId}`);

        try {
            const results = await this.allocationEngine.allocateInBatches(
                orderId,
                batchSize || 50,
            );

            console.log(`✅ Batch matching completed: ${results.length} batches`);

            return { success: true, batches: results.length };
        } catch (error) {
            console.error('Failed batch matching:', error);
            throw error;
        }
    }
}
