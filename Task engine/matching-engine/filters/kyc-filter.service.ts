import { Injectable } from '@nestjs/common';
import { WorkerRepository } from '../../shared/database/repositories/worker.repository';
import { MatchingContext } from '../types';

/**
 * KYC approved workers ko filter karta hai
 */
@Injectable()
export class KycFilterService {
    constructor(private readonly workerRepo: WorkerRepository) { }

    async apply(workerIds: string[], context: MatchingContext, loadedWorkers?: any[]): Promise<string[]> {
        const workers = loadedWorkers || await this.workerRepo.findByIds(workerIds);

        const kycApproved = workers.filter(worker =>
            worker.kycStatus === 'approved'
        );

        return kycApproved.map(w => w.id);
    }
}
