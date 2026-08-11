import { Injectable, Logger } from '@nestjs/common';
import { ReallocationEngine } from '../../shared/engines/reallocation-engine/reallocation.engine';

@Injectable()
export class TaskDeadlineService {
    private readonly logger = new Logger(TaskDeadlineService.name);

    constructor(private readonly reallocationEngine: ReallocationEngine) { }

    /**
     * Executes the Post-Deadline Monitor cycle.
     * Evaluates:
     * 1. Full Task Completion Timeouts: Replaces expired workers with reason WORKER_TIMEOUT (Only AFTER task deadline passes).
     * 2. Campaign Auto-Extensions: Extends campaign expiry by +10 hours if incomplete at cutoff date.
     */
    async runDeadlineMonitorCycle() {
        this.logger.log('Delegating Post-Deadline Monitor cycle to Reallocation Engine...');
        return this.reallocationEngine.runMonitorCycle();
    }

    async processExpiredTasks() {
        const result = await this.reallocationEngine.processFullTimeouts();
        return {
            expiredCount: result.expiredCount,
            reallocatedCount: result.reallocatedCount,
        };
    }
}
