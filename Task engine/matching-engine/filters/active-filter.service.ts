import { Injectable } from '@nestjs/common';
import { WorkerRepository } from '../../shared/database/repositories/worker.repository';
import { MatchingContext } from '../types';

/**
 * Active workers ko filter karta hai
 */
@Injectable()
export class ActiveFilterService {
    constructor(private readonly workerRepo: WorkerRepository) { }

    async apply(workerIds: string[], context: MatchingContext): Promise<string[]> {
        const workers = await this.workerRepo.findByIds(workerIds);

        const activeWorkers = workers.filter(worker =>
            worker.status === 'active'
        );

        return activeWorkers.map(w => w.id);
    }
}
