import { Injectable } from '@nestjs/common';
import { EarningCalculator } from './calculators/earning-calculator';
import { EarningPostingService } from './services/earning-posting.service';
import { NotificationEngineService } from '../notification-engine/notification.service';
import { EarningRepository } from '../shared/database/repositories/earning.repository';
import { WalletRepository } from '../shared/database/repositories/wallet.repository';
import { WorkerRepository } from '../shared/database/repositories/worker.repository';
import { WithdrawalRepository } from '../shared/database/repositories/withdrawal.repository';
import { WithdrawalStatus } from '../shared/database/entities/withdrawal.entity';
import { Earning } from './types/earning';

/**
 * Earning Engine
 * Worker ka earning calculate aur post karta hai, aur real wallet balance manage karta hai
 */
@Injectable()
export class EarningEngineService {
    constructor(
        private readonly calculator: EarningCalculator,
        private readonly postingService: EarningPostingService,
        private readonly notificationEngine: NotificationEngineService,
        private readonly earningRepo: EarningRepository,
        private readonly walletRepo: WalletRepository,
        private readonly workerRepo: WorkerRepository,
        private readonly withdrawalRepo: WithdrawalRepository,
    ) { }

    async calculateEarning(taskId: string, workerId: string): Promise<Earning> {
        const earning = await this.calculator.calculate(taskId, workerId);
        return earning;
    }

    async postEarning(earning: Earning): Promise<void> {
        await this.postingService.post(earning);
        await this.notificationEngine.sendNotification(
            earning.workerId,
            `Earnings of ₹${earning.amount.toFixed(2)} posted to your account for task ${earning.taskId}`,
            'EARNING_POSTED',
            { earningId: earning.id, taskId: earning.taskId, amount: earning.amount }
        );
    }

    async getAvailableBalance(workerId: string): Promise<number> {
        const worker = await this.workerRepo.findWorker(workerId);
        const workerIds = Array.from(new Set([workerId, worker?.id, worker?.userId].filter(Boolean) as string[]));

        const totalEarned = await this.earningRepo.getTotalEarnings(workerIds);
        const totalDeducted = await this.withdrawalRepo.getTotalWithdrawalsAmount(workerIds, [
            WithdrawalStatus.REQUESTED,
            WithdrawalStatus.UNDER_REVIEW,
            WithdrawalStatus.PROCESSING,
            WithdrawalStatus.PAID,
        ]);

        return Math.max(0, totalEarned - totalDeducted);
    }

    async reverseEarning(earningId: string): Promise<void> {
        await this.postingService.reverse(earningId);
    }
}
