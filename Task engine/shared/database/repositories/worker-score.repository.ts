import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { WorkerScore } from '../entities/worker-score.entity';

@Injectable()
export class WorkerScoreRepository {
    constructor(
        @InjectRepository(WorkerScore)
        private readonly repository: Repository<WorkerScore>,
    ) { }

    async findByWorkerId(workerId: string): Promise<WorkerScore | null> {
        return this.repository.findOne({ where: { workerId } });
    }

    async findByWorker(workerId: string): Promise<WorkerScore | null> {
        return this.findByWorkerId(workerId);
    }

    async findByWorkerIds(workerIds: string[]): Promise<WorkerScore[]> {
        if (!workerIds || workerIds.length === 0) return [];
        
        const chunkSize = 1000;
        const results: WorkerScore[] = [];
        
        for (let i = 0; i < workerIds.length; i += chunkSize) {
            const chunk = workerIds.slice(i, i + chunkSize);
            const chunkResults = await this.repository
                .createQueryBuilder('score')
                .where('score.workerId IN (:...chunk)', { chunk })
                .getMany();
            results.push(...chunkResults);
        }
        
        return results;
    }

    async upsert(workerId: string, scoreData: Partial<WorkerScore>): Promise<WorkerScore> {
        await this.repository.upsert(
            { workerId, ...scoreData },
            { conflictPaths: ['workerId'], skipUpdateIfNoValuesChanged: true }
        );
        return this.findByWorkerId(workerId) as Promise<WorkerScore>;
    }

    async getTopScorers(limit: number = 10): Promise<WorkerScore[]> {
        return this.repository.find({
            order: { totalScore: 'DESC' },
            take: limit,
        });
    }
}
