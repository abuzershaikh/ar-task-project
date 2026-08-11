import { Injectable } from '@nestjs/common';
import { WorkerRepository } from '../../shared/database/repositories/worker.repository';
import { MatchingContext } from '../types';

/**
 * Category/skill based filtering
 */
@Injectable()
export class CategoryFilterService {
    constructor(private readonly workerRepo: WorkerRepository) { }

    async apply(workerIds: string[], context: MatchingContext): Promise<string[]> {
        const requiredCategory = context.requirements?.category;

        if (!requiredCategory) {
            return workerIds;
        }

        const workers = await this.workerRepo.findByIds(workerIds);

        const matchingWorkers = workers.filter(worker => {
            const workerCategories = worker.profile?.categories || [];
            return workerCategories.includes(requiredCategory);
        });

        return matchingWorkers.map(w => w.id);
    }
}
