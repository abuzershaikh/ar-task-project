import { Injectable } from '@nestjs/common';
import { WorkerRepository } from '../../shared/database/repositories/worker.repository';
import { MatchingContext } from '../types';

/**
 * Category/skill based filtering
 */
@Injectable()
export class CategoryFilterService {
    constructor(private readonly workerRepo: WorkerRepository) { }

    async apply(workerIds: string[], context: MatchingContext, loadedWorkers?: any[]): Promise<string[]> {
        const requiredCategory = context.requirements?.category;

        if (!requiredCategory) {
            return workerIds;
        }

        const normalizedRequired = String(requiredCategory).trim().toLowerCase();
        const workers = loadedWorkers || await this.workerRepo.findByIds(workerIds);

        const matchingWorkers = workers.filter(worker => {
            const workerCategories: string[] = worker.profile?.categories || [];
            return workerCategories.some(cat => String(cat).trim().toLowerCase().includes(normalizedRequired));
        });

        return matchingWorkers.map(w => w.id);
    }
}
