import { Injectable } from '@nestjs/common';
import { WorkerRepository } from '../../shared/database/repositories/worker.repository';
import { MatchingContext } from '../types';

/**
 * Location based filtering
 * (Currently disabled / commented out for future implementation)
 */
@Injectable()
export class LocationFilterService {
    constructor(private readonly workerRepo: WorkerRepository) { }

    async apply(workerIds: string[], context: MatchingContext, loadedWorkers?: any[]): Promise<string[]> {
        // Location filter disabled for now - will be enabled in a future release.
        // Return all workerIds without restricting by location.
        return workerIds;

        /*
        const requiredLocation = context.requirements?.location;

        if (!requiredLocation) {
            return workerIds;
        }

        if (typeof requiredLocation === 'object' && !requiredLocation.city && !requiredLocation.state && !requiredLocation.country) {
            return workerIds;
        }

        if (typeof requiredLocation === 'string' && !requiredLocation.trim()) {
            return workerIds;
        }

        const workers = loadedWorkers || await this.workerRepo.findByIds(workerIds);

        const matchingWorkers = workers.filter(worker => {
            const workerLocation = worker.profile?.location;
            return this.matchesLocation(workerLocation, requiredLocation);
        });

        return matchingWorkers.map(w => w.id);
        */
    }

    /*
    private matchesLocation(workerLocation: any, requiredLocation: any): boolean {
        if (!workerLocation) return false;

        // Both or either can be string or object
        if (typeof requiredLocation === 'string') {
            const reqStr = requiredLocation.trim().toLowerCase();
            if (typeof workerLocation === 'string') {
                const wStr = workerLocation.trim().toLowerCase();
                return wStr.includes(reqStr) || reqStr.includes(wStr);
            }
            if (typeof workerLocation === 'object') {
                const wCity = (workerLocation.city || '').trim().toLowerCase();
                const wState = (workerLocation.state || '').trim().toLowerCase();
                const wCountry = (workerLocation.country || '').trim().toLowerCase();
                return (wCity && reqStr.includes(wCity)) || 
                       (wState && reqStr.includes(wState)) || 
                       (wCountry && reqStr.includes(wCountry)) ||
                       (wCity && wCity.includes(reqStr)) ||
                       (wCountry && wCountry.includes(reqStr));
            }
            return false;
        }

        // requiredLocation is an object { city, state, country }
        if (typeof workerLocation === 'string') {
            const wStr = workerLocation.trim().toLowerCase();
            if (requiredLocation.city && !wStr.includes(requiredLocation.city.trim().toLowerCase())) {
                return false;
            }
            if (requiredLocation.state && !wStr.includes(requiredLocation.state.trim().toLowerCase())) {
                return false;
            }
            if (requiredLocation.country && !wStr.includes(requiredLocation.country.trim().toLowerCase())) {
                return false;
            }
            return true;
        }

        // Both are objects
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
    */
}
