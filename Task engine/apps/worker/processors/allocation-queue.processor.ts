import { Processor, Process } from '@nestjs/bull';
import { Job } from 'bull';
import { Injectable } from '@nestjs/common';
import { AllocationEngineService } from '../../../allocation-engine/allocation.service';

/**
 * Allocation queue processor
 * Tasks ko workers assign karta hai
 */
@Processor('allocation')
@Injectable()
export class AllocationQueueProcessor {
    constructor(private readonly allocationEngine: AllocationEngineService) { }

    @Process('allocate-tasks')
    async handleAllocateTasks(job: Job) {
        const { taskIds, workerIds, strategy } = job.data;

        console.log(`🎯 Allocating ${taskIds.length} tasks to ${workerIds.length} workers`);

        try {
            const result = await this.allocationEngine.allocateTasks({
                taskIds,
                workerIds,
                strategy: strategy || 'sequential',
            });

            console.log(`✅ Allocation complete: ${result.successCount} success, ${result.failedCount} failed`);

            return result;
        } catch (error) {
            console.error('Failed to allocate tasks:', error);
            throw error;
        }
    }

    @Process('rebalance-tasks')
    async handleRebalanceTasks(job: Job) {
        console.log('⚖️ Rebalancing task allocation...');

        // TODO: Implement rebalancing logic
        // Redistribute tasks from overloaded workers to underloaded workers

        return { success: true };
    }
}
