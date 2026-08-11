import { Injectable } from '@nestjs/common';
import { AssignmentService } from './services/assignment.service';
import { BatchService } from './services/batch.service';
import { AllocationRequest, AllocationResult } from './types';

/**
 * Allocation Engine
 * Workers ko tasks assign karta hai
 */
@Injectable()
export class AllocationEngineService {
    constructor(
        private readonly assignmentService: AssignmentService,
        private readonly batchService: BatchService,
    ) { }

    async allocateTasks(request: AllocationRequest): Promise<AllocationResult> {
        // Strategy based allocation
        const result = await this.assignmentService.assign(request);
        return result;
    }

    async allocateInBatches(
        orderId: string,
        batchSize: number,
    ): Promise<AllocationResult[]> {
        const results = await this.batchService.processBatches(orderId, batchSize);
        return results;
    }
}
