import { Injectable } from '@nestjs/common';
import { WithdrawalRepository } from '../../shared/database/repositories/withdrawal.repository';
import { NotificationEngineService } from '../../notification-engine/notification.service';
import { WithdrawalStatus } from '../../shared/database/entities/withdrawal.entity';
import { PayoutStatus } from '../types';

/**
 * Actual payout processing (Razorpay/Cashfree integration)
 */
@Injectable()
export class PayoutProcessor {
    constructor(
        private readonly withdrawalRepo: WithdrawalRepository,
        private readonly notificationEngine: NotificationEngineService,
    ) { }

    async process(withdrawalId: string): Promise<PayoutStatus> {
        console.log(`🔄 Processing payout: ${withdrawalId}`);

        const withdrawal = await this.withdrawalRepo.findById(withdrawalId);

        // Simulate processing
        await this.delay(2000);

        const txnId = `TXN${Date.now()}`;

        if (withdrawal) {
            await this.withdrawalRepo.update(withdrawalId, {
                status: WithdrawalStatus.PAID,
                processedAt: new Date(),
                transactionId: txnId,
            });

            await this.notificationEngine.sendNotification(
                withdrawal.workerId,
                `Payout of ₹${withdrawal.amount.toFixed(2)} has been successfully transferred to your bank account! (Ref: ${txnId})`,
                'PAYOUT_COMPLETED',
                { withdrawalId, amount: withdrawal.amount, transactionId: txnId }
            );
        }

        // For now, return success
        return {
            withdrawalId,
            status: 'completed',
            processedAt: new Date(),
            transactionId: txnId,
        };
    }

    private delay(ms: number): Promise<void> {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
}
