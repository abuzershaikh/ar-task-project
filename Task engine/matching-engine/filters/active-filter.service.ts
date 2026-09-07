import { Injectable, Logger } from '@nestjs/common';
import { WorkerRepository } from '../../shared/database/repositories/worker.repository';
import { MatchingContext } from '../types';

/**
 * Active workers ko filter karta hai
 * 
 * NEW RULES:
 * 1. Worker status must be 'active'
 * 2. lastActiveAt < 48 hours (hard gate)
 * 3. Worker must NOT be on task cooldown
 */
@Injectable()
export class ActiveFilterService {
    private readonly logger = new Logger(ActiveFilterService.name);

    constructor(private readonly workerRepo: WorkerRepository) { }

    async apply(workerIds: string[], context: MatchingContext, loadedWorkers?: any[]): Promise<string[]> {
        const workers = loadedWorkers || await this.workerRepo.findByIds(workerIds);

        const activeWorkers = workers.filter(worker => {
            // Rule 1: Status must be active
            if (worker.status !== 'active') return false;

            // Rule 2: Activity check — 48h hard gate
            if (!this.workerRepo.isActivityEligible(worker)) {
                this.logger.debug(`Worker ${worker.id} filtered out: ${this.workerRepo.getActivityStatus(worker)} (lastActiveAt: ${worker.lastActiveAt})`);
                return false;
            }

            // Rule 3: Cooldown check
            if (this.workerRepo.isOnCooldown(worker)) {
                this.logger.debug(`Worker ${worker.id} filtered out: on task cooldown until ${worker.taskCooldownUntil}`);
                return false;
            }

            return true;
        });

        if (workers.length !== activeWorkers.length) {
            this.logger.log(`Active filter: ${workers.length} → ${activeWorkers.length} workers (removed ${workers.length - activeWorkers.length} inactive/cooldown)`);
        }

        return activeWorkers.map(w => w.id);
    }
}
