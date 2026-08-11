import { Injectable } from '@nestjs/common';
import { TaskRepository } from '../../shared/database/repositories/task.repository';
import { MatchingContext } from '../types';

/**
 * Worker ki current capacity check karta hai
 */
@Injectable()
export class CapacityFilterService {
    constructor(private readonly taskRepo: TaskRepository) { }

    async apply(workerIds: string[], context: MatchingContext): Promise<string[]> {
        const MAX_CONCURRENT_TASKS = 5; // Worker can handle max 5 tasks at once

        const eligibleWorkers: string[] = [];

        for (const workerId of workerIds) {
            // Count active tasks assigned to this worker
            const activeTasks = await this.taskRepo.findByWorker(workerId);
            const activeCount = activeTasks.filter(
                t => ['assigned', 'accepted', 'in_progress'].includes(t.status)
            ).length;

            if (activeCount < MAX_CONCURRENT_TASKS) {
                eligibleWorkers.push(workerId);
            }
        }

        return eligibleWorkers;
    }
}
