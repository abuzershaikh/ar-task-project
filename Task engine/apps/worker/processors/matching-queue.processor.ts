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

                const allocResult = await this.allocationEngine.allocateTasks({
                    taskIds: [taskId],
                    workerIds: [topWorker.workerId],
                    pairs: [{ taskId, workerId: topWorker.workerId }],
                    strategy: 'sequential',
                });

                if (allocResult.failedCount > 0 || allocResult.successCount === 0) {
                    throw new Error(`Allocation failed for task ${taskId} to worker ${topWorker.workerId}`);
                }

                console.log(`✅ [Telemetry] Task ${taskId} allocated to worker ${topWorker.workerId}. Candidate pool: ${result.totalCandidates}, Matched: ${result.matchedWorkers.length}`);
            } else {
                console.warn(`⚠️ [Telemetry] Zero candidates matched for task ${taskId}. Job ID: ${job.id}`);
            }

            return { success: true, matchedCount: result.matchedWorkers.length, candidates: result.totalCandidates };
        } catch (error) {
            console.error(`❌ [Telemetry] Failed to match/allocate workers for task ${taskId} (Job ID: ${job.id}):`, error.message || error);
            throw error;
        }
    }

    @Process('batch-match')
    async handleBatchMatch(job: Job) {
        const { orderId, batchSize } = job.data;

        console.log(`📦 Batch matching for order ${orderId} (Job ID: ${job.id})`);

        try {
            const results = await this.allocationEngine.allocateInBatches(
                orderId,
                batchSize || 50,
            );

            const totalAllocated = results.reduce((acc, r) => acc + r.successCount, 0);
            const totalFailed = results.reduce((acc, r) => acc + r.failedCount, 0);

            if (totalFailed > 0) {
                console.warn(`⚠️ [Telemetry] Batch matching had ${totalFailed} failures/unmatched tasks for order ${orderId}. Throwing error to trigger Bull retry.`);
                throw new Error(`Batch matching incomplete: ${totalFailed} tasks failed to allocate or match.`);
            }

            console.log(`✅ [Telemetry] Batch matching completed for order ${orderId}: ${results.length} batches, ${totalAllocated} allocated, 0 failed.`);

            return { success: true, batches: results.length, allocatedCount: totalAllocated, failedCount: 0 };
        } catch (error) {
            console.error(`❌ [Telemetry] Failed batch matching for order ${orderId}:`, error.message || error);
            throw error;
        }
    }
}
