import { Injectable } from '@nestjs/common';
import { WorkerRepository } from '../../shared/database/repositories/worker.repository';
import { MatchingContext } from '../types';

/**
 * Location based filtering
 */
@Injectable()
export class LocationFilterService {
    constructor(private readonly workerRepo: WorkerRepository) { }

    async apply(workerIds: string[], context: MatchingContext): Promise<string[]> {
        const requiredLocation = context.requirements?.location;

        if (!requiredLocation) {
            return workerIds; // No location requirement
        }

        const workers = await this.workerRepo.findByIds(workerIds);

        const matchingWorkers = workers.filter(worker => {
            const workerLocation = worker.profile?.location;
            return this.matchesLocation(workerLocation, requiredLocation);
        });

        return matchingWorkers.map(w => w.id);
    }

    private matchesLocation(workerLocation: any, requiredLocation: any): boolean {
        if (!workerLocation) return false;

        // Exact match
        if (workerLocation.city === requiredLocation.city) return true;

        // State match
        if (workerLocation.state === requiredLocation.state) return true;

        // Country match
        if (workerLocation.country === requiredLocation.country) return true;

        return false;
    }
}
