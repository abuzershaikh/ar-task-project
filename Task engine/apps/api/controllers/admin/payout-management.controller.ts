import {
    Controller,
    Get,
    Post,
    Param,
    Body,
    NotFoundException,
    BadRequestException,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { WithdrawalRepository } from '../../../../shared/database/repositories/withdrawal.repository';
import { WorkerRepository } from '../../../../shared/database/repositories/worker.repository';
import { UserRepository } from '../../../../shared/database/repositories/user.repository';
import { PayoutEngineService } from '../../../../payout-engine/payout.service';
import { WithdrawalStatus } from '../../../../shared/database/entities/withdrawal.entity';
import { Roles } from '../../../../shared/auth/decorators/roles.decorator';
import { UserRole } from '../../../../shared/database/entities/user.entity';

@ApiTags('Admin - Payout Management')
@Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
@ApiBearerAuth('bearer')
@Controller('admin/payouts')
export class AdminPayoutManagementController {
    constructor(
        private readonly withdrawalRepo: WithdrawalRepository,
        private readonly payoutEngine: PayoutEngineService,
        private readonly workerRepo: WorkerRepository,
        private readonly userRepo: UserRepository,
    ) { }

    @Get('config')
    @ApiOperation({ summary: 'Get global minimum withdrawal threshold configuration' })
    async getPayoutConfig() {
        return {
            success: true,
            minWithdrawalLimit: this.payoutEngine.getMinWithdrawalLimit(),
        };
    }

    @Post('config')
    @ApiOperation({ summary: 'Update global minimum withdrawal threshold limit' })
    async updatePayoutConfig(@Body() body: { minWithdrawalLimit: number }) {
        if (typeof body.minWithdrawalLimit !== 'number' || body.minWithdrawalLimit < 0) {
            throw new BadRequestException('minWithdrawalLimit must be a positive number');
        }

        this.payoutEngine.setMinWithdrawalLimit(body.minWithdrawalLimit);
        return {
            success: true,
            minWithdrawalLimit: this.payoutEngine.getMinWithdrawalLimit(),
            message: `Global minimum withdrawal threshold updated to ₹${body.minWithdrawalLimit}`,
        };
    }

    @Get('pending')
    @ApiOperation({ summary: 'List pending worker withdrawal requests' })
    async getPendingPayouts() {
        const withdrawals = await this.withdrawalRepo.findPending();

        const enriched = await Promise.all(
            withdrawals.map(async (w) => {
                let worker = await this.workerRepo.findById(w.workerId);
                if (!worker) {
                    worker = await this.workerRepo.findByUserId(w.workerId);
                }
                const userId = worker ? worker.userId : w.workerId;
                const user = await this.userRepo.findById(userId);

                const bankDetails = worker?.profile?.bankDetails;
                let paymentMethod = w.paymentMethodId;
                if (!paymentMethod || paymentMethod === 'DEFAULT') {
                    paymentMethod = bankDetails?.upiId ? `UPI (${bankDetails.upiId})` : 
                                    (bankDetails?.accountNumber ? `${bankDetails?.bankName || 'Bank'}: ${bankDetails.accountNumber}` : 'UPI / Bank');
                } else if (!paymentMethod.includes(':') && !paymentMethod.includes('(') && paymentMethod.includes('@')) {
                    paymentMethod = `UPI (${paymentMethod})`;
                }

                return {
                    ...w,
                    workerId: worker?.id || w.workerId,
                    userId,
                    workerName: user?.fullName || (worker as any)?.fullName || 'Worker Account',
                    workerEmail: user?.email || '',
                    workerPhone: user?.phone || (worker as any)?.phone || '',
                    avatarUrl: user?.avatarUrl || '',
                    workerAvatarUrl: user?.avatarUrl || '',
                    paymentMethod,
                    paymentMethodId: w.paymentMethodId,
                    bankDetails: bankDetails || null,
                };
            }),
        );

        return {
            success: true,
            withdrawals: enriched,
            count: enriched.length,
        };
    }

    @Post(':withdrawalId/process')
    @ApiOperation({ summary: 'Mark withdrawal as PAID and release reserved funds' })
    async processPayout(
        @Param('withdrawalId') withdrawalId: string,
        @Body() body?: { transactionId?: string; providerReference?: string },
    ) {
        const txnId = body?.transactionId || `PAYOUT-${Date.now()}`;
        const updated = await this.payoutEngine.markAsPaid(withdrawalId, {
            transactionId: txnId,
            providerReference: body?.providerReference || 'ADMIN_APP_PROCESSED',
        });
        return {
            success: true,
            withdrawal: updated,
            message: 'Withdrawal approved, processed, and marked as PAID',
        };
    }

    @Post(':withdrawalId/mark-paid')
    @ApiOperation({ summary: 'Mark withdrawal as PAID with transaction reference' })
    async markPaid(
        @Param('withdrawalId') withdrawalId: string,
        @Body() body: { transactionId?: string; providerReference?: string },
    ) {
        const updated = await this.payoutEngine.markAsPaid(withdrawalId, body);
        return {
            success: true,
            withdrawal: updated,
            message: 'Withdrawal marked as PAID',
        };
    }

    @Post(':withdrawalId/reject')
    @ApiOperation({ summary: 'Reject withdrawal and refund balance' })
    async rejectPayout(
        @Param('withdrawalId') withdrawalId: string,
        @Body() body: { reason: string },
    ) {
        const updated = await this.payoutEngine.reject(withdrawalId, body?.reason);
        return {
            success: true,
            withdrawal: updated,
            message: 'Withdrawal rejected and balance released/refunded',
        };
    }
}
