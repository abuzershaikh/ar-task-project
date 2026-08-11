import { Injectable, BadRequestException } from '@nestjs/common';
import { EarningRepository } from '../../shared/database/repositories/earning.repository';
import { WithdrawalRepository } from '../../shared/database/repositories/withdrawal.repository';
import { WorkerRepository } from '../../shared/database/repositories/worker.repository';
import { PayoutConfigService } from './payout-config.service';
import { WithdrawalStatus } from '../../shared/database/entities/withdrawal.entity';
import { PayoutRequest } from '../types';

/**
 * Withdrawal request create aur manage karta hai
 */
@Injectable()
export class WithdrawalService {
    constructor(
        private readonly earningRepo: EarningRepository,
        private readonly withdrawalRepo: WithdrawalRepository,
        private readonly workerRepo: WorkerRepository,
        private readonly configService: PayoutConfigService,
    ) { }

    async create(request: PayoutRequest): Promise<string> {
        const { workerId, amount, paymentMethod, idempotencyKey, metadata } = request;

        // Idempotency check
        if (idempotencyKey) {
            const existing = await this.withdrawalRepo.findByIdempotencyKey(idempotencyKey);
            if (existing) {
                return existing.id;
            }
        }

        // Get worker minimum withdrawal limit setting
        const worker = await this.workerRepo.findByUserId(workerId) || await this.workerRepo.findById(workerId);
        const minLimit = worker?.profile?.minWithdrawalLimit || this.configService.getGlobalMinWithdrawalLimit();

        if (amount < minLimit) {
            throw new BadRequestException(
                `Minimum withdrawal threshold is ₹${minLimit.toFixed(2)}. Your requested amount of ₹${amount.toFixed(2)} does not meet the minimum requirement.`,
            );
        }

        // Calculate available balance
        const totalEarned = await this.earningRepo.getTotalEarnings(workerId);
        const totalDeducted = await this.withdrawalRepo.getTotalWithdrawalsAmount(workerId, [
            WithdrawalStatus.REQUESTED,
            WithdrawalStatus.UNDER_REVIEW,
            WithdrawalStatus.PROCESSING,
            WithdrawalStatus.PAID,
        ]);

        const availableBalance = Math.max(0, totalEarned - totalDeducted);

        if (amount > availableBalance) {
            throw new BadRequestException(
                `Insufficient balance. Available: ₹${availableBalance.toFixed(2)}, Requested: ₹${amount.toFixed(2)}`,
            );
        }

        const withdrawal = await this.withdrawalRepo.create({
            workerId,
            amount,
            status: WithdrawalStatus.REQUESTED,
            paymentMethodId: paymentMethod || 'DEFAULT',
            requestedAt: new Date(),
            idempotencyKey,
            metadata,
        });

        console.log(`💰 Withdrawal initiated: ${withdrawal.id} - ₹${amount} (Min Limit: ₹${minLimit})`);
        return withdrawal.id;
    }

    async getBalance(workerId: string): Promise<number> {
        const totalEarned = await this.earningRepo.getTotalEarnings(workerId);
        const totalDeducted = await this.withdrawalRepo.getTotalWithdrawalsAmount(workerId, [
            WithdrawalStatus.REQUESTED,
            WithdrawalStatus.UNDER_REVIEW,
            WithdrawalStatus.PROCESSING,
            WithdrawalStatus.PAID,
        ]);

        return Math.max(0, totalEarned - totalDeducted);
    }
}
