import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Earning } from '../entities/earning.entity';

@Injectable()
export class EarningRepository {
    constructor(
        @InjectRepository(Earning)
        private readonly repository: Repository<Earning>,
    ) { }

    async findById(id: string): Promise<Earning | null> {
        return this.repository.findOne({ where: { id } });
    }

    async findByTaskId(taskId: string): Promise<Earning | null> {
        return this.repository.findOne({ where: { taskId } });
    }

    async findByWorker(workerId: string): Promise<Earning[]> {
        return this.repository.find({
            where: { workerId },
            order: { createdAt: 'DESC' },
        });
    }

    async getTotalEarnings(workerId: string): Promise<number> {
        const result = await this.repository
            .createQueryBuilder('earning')
            .select('SUM(earning.amount)', 'total')
            .where('earning.worker_id = :workerId', { workerId })
            .andWhere('earning.status = :status', { status: 'posted' })
            .getRawOne();

        return parseFloat(result?.total || 0);
    }

    async create(data: Partial<Earning>): Promise<Earning> {
        const earning = this.repository.create(data);
        return this.repository.save(earning);
    }

    async update(id: string, data: Partial<Earning>): Promise<Earning> {
        await this.repository.update(id, data);
        return this.findById(id);
    }
}
