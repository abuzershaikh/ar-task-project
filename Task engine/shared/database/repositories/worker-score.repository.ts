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
        return this.repository
            .createQueryBuilder('score')
            .where('score.workerId IN (:...workerIds)', { workerIds })
            .getMany();
    }

    async upsert(workerId: string, scoreData: Partial<WorkerScore>): Promise<WorkerScore> {
        const existing = await this.findByWorkerId(workerId);

        if (existing) {
            await this.repository.update(existing.id, scoreData);
            return this.findByWorkerId(workerId);
        }

        const score = this.repository.create({ workerId, ...scoreData });
        return this.repository.save(score);
    }

    async getTopScorers(limit: number = 10): Promise<WorkerScore[]> {
        return this.repository.find({
            order: { totalScore: 'DESC' },
            take: limit,
        });
    }
}
