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

    async findProcessed(): Promise<Withdrawal[]> {
        return this.repository.find({
            where: { status: WithdrawalStatus.PAID },
            order: { paidAt: 'DESC', createdAt: 'DESC' },
        });
    }

    async findAll(status?: string): Promise<Withdrawal[]> {
        if (status && status !== 'ALL') {
            const upperStatus = status.toUpperCase();
            if (upperStatus === 'PENDING') {
                return this.findPending();
            }
            if (upperStatus === 'PROCESSED' || upperStatus === 'PAID') {
                return this.findProcessed();
            }
            return this.repository.find({
                where: { status: upperStatus as WithdrawalStatus },
                order: { createdAt: 'DESC' },
            });
        }
        return this.repository.find({
            order: { createdAt: 'DESC' },
        });
    }

    async getStats(): Promise<{
        pendingCount: number;
        pendingAmount: number;
        paidCount: number;
        paidAmount: number;
        rejectedCount: number;
        rejectedAmount: number;
        totalCount: number;
        totalAmount: number;
    }> {
        const rows = await this.repository
            .createQueryBuilder('w')
            .select('w.status', 'status')
            .addSelect('COUNT(w.id)', 'count')
            .addSelect('COALESCE(SUM(w.amount), 0)', 'total')
            .groupBy('w.status')
            .getRawMany();

        let pendingCount = 0;
        let pendingAmount = 0;
        let paidCount = 0;
        let paidAmount = 0;
        let rejectedCount = 0;
        let rejectedAmount = 0;
        let totalCount = 0;
        let totalAmount = 0;

        for (const row of rows) {
            const count = parseInt(row.count, 10) || 0;
            const amount = parseFloat(row.total) || 0;
            totalCount += count;
            totalAmount += amount;

            if (row.status === WithdrawalStatus.PAID) {
                paidCount += count;
                paidAmount += amount;
            } else if (
                row.status === WithdrawalStatus.REQUESTED ||
                row.status === WithdrawalStatus.UNDER_REVIEW ||
                row.status === WithdrawalStatus.PROCESSING
            ) {
                pendingCount += count;
                pendingAmount += amount;
            } else if (row.status === WithdrawalStatus.REJECTED || row.status === WithdrawalStatus.FAILED) {
                rejectedCount += count;
                rejectedAmount += amount;
            }
        }

        return {
            pendingCount,
            pendingAmount,
            paidCount,
            paidAmount,
            rejectedCount,
            rejectedAmount,
            totalCount,
            totalAmount,
        };
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
