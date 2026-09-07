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

    async findByWorker(workerId: string | string[]): Promise<Earning[]> {
        const ids = Array.isArray(workerId) ? workerId : [workerId];
        return this.repository
            .createQueryBuilder('earning')
            .where('earning.worker_id IN (:...ids)', { ids })
            .orderBy('earning.created_at', 'DESC')
            .getMany();
    }

    async getTotalEarnings(workerId: string | string[]): Promise<number> {
        const ids = Array.isArray(workerId) ? workerId : [workerId];
        const result = await this.repository
            .createQueryBuilder('earning')
            .select('SUM(earning.amount)', 'total')
            .where('earning.worker_id IN (:...ids)', { ids })
            .andWhere('earning.status = :status', { status: 'posted' })
            .getRawOne();

        return parseFloat(result?.total || 0);
    }

    async sumTotalEarnings(): Promise<number> {
        const result = await this.repository
            .createQueryBuilder('earning')
            .select('SUM(earning.amount)', 'total')
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
