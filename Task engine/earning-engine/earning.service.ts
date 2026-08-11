import { Injectable } from '@nestjs/common';
import { EarningCalculator } from './calculators/earning-calculator';
import { EarningPostingService } from './services/earning-posting.service';
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
    ) { }

    async calculateEarning(taskId: string, workerId: string): Promise<Earning> {
        const earning = await this.calculator.calculate(taskId, workerId);
        return earning;
    }

    async postEarning(earning: Earning): Promise<void> {
        await this.postingService.post(earning);
    }

    async reverseEarning(earningId: string): Promise<void> {
        await this.postingService.reverse(earningId);
    }
}
