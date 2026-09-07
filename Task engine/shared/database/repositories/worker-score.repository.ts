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
        if (!workerId) return null;
        let score = await this.findByWorkerId(workerId);
        if (!score) {
            score = await this.repository.createQueryBuilder('ws')
                .where('ws.workerId = :workerId', { workerId })
                .orWhere('ws.workerId IN (SELECT w.id FROM workers w WHERE w.user_id = :workerId)', { workerId })
                .orWhere('ws.workerId IN (SELECT w.user_id FROM workers w WHERE w.id = :workerId)', { workerId })
                .getOne();
        }
        return score;
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
        const payload: any = {
            workerId,
            totalScore: scoreData.totalScore ?? 0,
            qualityScore: scoreData.qualityScore ?? 0,
            completionScore: scoreData.completionScore ?? 0,
            reliabilityScore: scoreData.reliabilityScore ?? 0,
            ratingScore: scoreData.ratingScore ?? 0,
            recentPerformanceScore: scoreData.recentPerformanceScore ?? 0,
            experienceScore: scoreData.experienceScore ?? 0,
            breakdown: scoreData.breakdown || {},
            updatedAt: new Date(),
        };

        const existing = await this.findByWorkerId(workerId);
        if (existing) {
            await this.repository.update(existing.id, payload);
        } else {
            const entity = this.repository.create(payload);
            await this.repository.save(entity);
        }
        return this.findByWorkerId(workerId) as Promise<WorkerScore>;
    }

    async getTopScorers(limit: number = 10): Promise<WorkerScore[]> {
        return this.repository.find({
            order: { totalScore: 'DESC' },
            take: limit,
        });
    }
}
