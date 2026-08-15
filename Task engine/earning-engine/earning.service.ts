import { Injectable } from '@nestjs/common';
import { EarningCalculator } from './calculators/earning-calculator';
import { EarningPostingService } from './services/earning-posting.service';
import { NotificationEngineService } from '../notification-engine/notification.service';
import { EarningRepository } from '../shared/database/repositories/earning.repository';
import { Earning } from './types/earning';

/**
 * Earning Engine
 * Worker ka earning calculate aur post karta hai
 */
@Injectable()
export class EarningEngineService {
    constructor(
        private readonly calculator: EarningCalculator,
        private readonly postingService: EarningPostingService,
        private readonly notificationEngine: NotificationEngineService,
        private readonly earningRepo: EarningRepository,
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
        return this.earningRepo.getTotalEarnings(workerId);
    }

    async reverseEarning(earningId: string): Promise<void> {
        await this.postingService.reverse(earningId);
    }
}
