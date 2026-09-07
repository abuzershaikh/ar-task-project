import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Withdrawal, WithdrawalStatus } from '../entities/withdrawal.entity';

@Injectable()
export class WithdrawalRepository {
    constructor(
        @InjectRepository(Withdrawal)
        private readonly repository: Repository<Withdrawal>,
    ) { }

    async findById(id: string): Promise<Withdrawal | null> {
        return this.repository.findOne({ where: { id } });
    }

    async findByIdempotencyKey(key: string): Promise<Withdrawal | null> {
        return this.repository.findOne({ where: { idempotencyKey: key } });
    }

    async findByWorker(workerId: string | string[]): Promise<Withdrawal[]> {
        const ids = Array.isArray(workerId) ? workerId : [workerId];
        return this.repository
            .createQueryBuilder('withdrawal')
            .where('withdrawal.worker_id IN (:...ids)', { ids })
            .orderBy('withdrawal.created_at', 'DESC')
            .getMany();
    }

    async findPending(): Promise<Withdrawal[]> {
        return this.repository.find({
            where: [
                { status: WithdrawalStatus.REQUESTED },
                { status: WithdrawalStatus.UNDER_REVIEW },
                { status: WithdrawalStatus.PROCESSING },
            ],
            order: { createdAt: 'ASC' },
        });
    }

    async getTotalWithdrawalsAmount(workerId: string | string[], statuses: WithdrawalStatus[]): Promise<number> {
        if (!statuses || statuses.length === 0) return 0;
        const ids = Array.isArray(workerId) ? workerId : [workerId];

        const result = await this.repository
            .createQueryBuilder('withdrawal')
            .select('SUM(withdrawal.amount)', 'total')
            .where('withdrawal.worker_id IN (:...ids)', { ids })
            .andWhere('withdrawal.status IN (:...statuses)', { statuses })
            .getRawOne();

        return parseFloat(result?.total || 0);
    }

    async sumPaidWithdrawals(): Promise<number> {
        const result = await this.repository
            .createQueryBuilder('withdrawal')
            .select('SUM(withdrawal.amount)', 'total')
            .where('withdrawal.status = :status', { status: WithdrawalStatus.PAID })
            .getRawOne();

        return parseFloat(result?.total || 0);
    }

    async create(data: Partial<Withdrawal>): Promise<Withdrawal> {
        const withdrawal = this.repository.create(data);
        return this.repository.save(withdrawal);
    }

    async update(id: string, data: Partial<Withdrawal>): Promise<Withdrawal> {
        await this.repository.update(id, data);
        return this.findById(id);
    }
}
