import { Injectable } from '@nestjs/common';
import { WorkerRepository } from '../../shared/database/repositories/worker.repository';
import { MatchingContext } from '../types';

/**
 * Location based filtering
 */
@Injectable()
export class LocationFilterService {
    constructor(private readonly workerRepo: WorkerRepository) { }

    async apply(workerIds: string[], context: MatchingContext, loadedWorkers?: any[]): Promise<string[]> {
        const requiredLocation = context.requirements?.location;

        if (!requiredLocation || (!requiredLocation.city && !requiredLocation.state && !requiredLocation.country)) {
            return workerIds;
        }

        const workers = loadedWorkers || await this.workerRepo.findByIds(workerIds);

        const matchingWorkers = workers.filter(worker => {
            const workerLocation = worker.profile?.location;
            return this.matchesLocation(workerLocation, requiredLocation);
        });

        return matchingWorkers.map(w => w.id);
    }

    private matchesLocation(workerLocation: any, requiredLocation: any): boolean {
        if (!workerLocation) return false;

        if (requiredLocation.city) {
            if (!workerLocation.city || workerLocation.city.trim().toLowerCase() !== requiredLocation.city.trim().toLowerCase()) {
                return false;
            }
        }

        if (requiredLocation.state) {
            if (!workerLocation.state || workerLocation.state.trim().toLowerCase() !== requiredLocation.state.trim().toLowerCase()) {
                return false;
            }
        }

        if (requiredLocation.country) {
            if (!workerLocation.country || workerLocation.country.trim().toLowerCase() !== requiredLocation.country.trim().toLowerCase()) {
                return false;
            }
        }

        return true;
    }
}
