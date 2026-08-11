import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Rating } from '../entities/rating.entity';

@Injectable()
export class RatingRepository {
    constructor(
        @InjectRepository(Rating)
        private readonly repository: Repository<Rating>,
    ) { }

    async findById(id: string): Promise<Rating | null> {
        return this.repository.findOne({ where: { id } });
    }

    async findByTaskId(taskId: string): Promise<Rating | null> {
        return this.repository.findOne({ where: { taskId } });
    }

    async findByWorkerId(workerId: string): Promise<Rating[]> {
        return this.repository.find({
            where: { workerId },
            order: { createdAt: 'DESC' },
        });
    }

    async findByBuyerId(buyerId: string): Promise<Rating[]> {
        return this.repository.find({
            where: { buyerId },
            order: { createdAt: 'DESC' },
        });
    }

    async getWorkerRatingSummary(workerId: string): Promise<{ average: number; count: number }> {
        const result = await this.repository
            .createQueryBuilder('rating')
            .select('AVG(rating.rating)', 'average')
            .addSelect('COUNT(rating.id)', 'count')
            .where('rating.worker_id = :workerId', { workerId })
            .getRawOne();

        return {
            average: parseFloat(result?.average || 0),
            count: parseInt(result?.count || 0, 10),
        };
    }

    async create(data: Partial<Rating>): Promise<Rating> {
        const rating = this.repository.create(data);
        return this.repository.save(rating);
    }
}
