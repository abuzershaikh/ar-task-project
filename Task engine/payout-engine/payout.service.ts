import { Injectable } from '@nestjs/common';
import { WithdrawalService } from './services/withdrawal.service';
import { PayoutProcessor } from './processors/payout-processor';
import { PayoutConfigService } from './services/payout-config.service';
import { PayoutRequest, PayoutStatus } from './types';

/**
 * Payout Engine
 * Worker ke withdrawal request ko process karta hai
 */
@Injectable()
export class PayoutEngineService {
    constructor(
        private readonly withdrawalService: WithdrawalService,
        private readonly processor: PayoutProcessor,
        private readonly configService: PayoutConfigService,
    ) { }

    async initiateWithdrawal(request: PayoutRequest): Promise<string> {
        const withdrawalId = await this.withdrawalService.create(request);
        return withdrawalId;
    }

    async processPayout(withdrawalId: string): Promise<PayoutStatus> {
        const status = await this.processor.process(withdrawalId);
        return status;
    }

    getMinWithdrawalLimit(): number {
        return this.configService.getGlobalMinWithdrawalLimit();
    }

    setMinWithdrawalLimit(limit: number): void {
        this.configService.setGlobalMinWithdrawalLimit(limit);
    }
}
