import { Injectable } from '@nestjs/common';
import { TaskRepository } from '../../shared/database/repositories/task.repository';
import { MatchingContext } from '../types';

/**
 * Worker ki current capacity check karta hai
 */
@Injectable()
export class CapacityFilterService {
    constructor(private readonly taskRepo: TaskRepository) { }

    async apply(workerIds: string[], context: MatchingContext, activeCountsMap?: Map<string, number>): Promise<string[]> {
        const MAX_CONCURRENT_TASKS = 5; // Worker can handle max 5 tasks at once

        if (!workerIds || workerIds.length === 0) return [];

        // Use pre-calculated map if provided, otherwise fetch
        let map = activeCountsMap;
        if (!map) {
            map = await this.taskRepo.getWorkerActiveTaskCounts(workerIds);
        }

        return workerIds.filter(workerId => {
            const activeCount = map?.get(workerId) || 0;
            return activeCount < MAX_CONCURRENT_TASKS;
        });
    }
}
