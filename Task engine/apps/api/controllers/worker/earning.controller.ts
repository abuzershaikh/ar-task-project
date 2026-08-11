import {
    Controller,
    Get,
    Post,
    Body,
    BadRequestException,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { EarningRepository } from '../../../../shared/database/repositories/earning.repository';
import { WithdrawalRepository } from '../../../../shared/database/repositories/withdrawal.repository';
import { WorkerRepository } from '../../../../shared/database/repositories/worker.repository';
import { WithdrawalStatus } from '../../../../shared/database/entities/withdrawal.entity';
import { PayoutEngineService } from '../../../../payout-engine/payout.service';
import { CurrentUser } from '../../../../shared/auth/decorators/current-user.decorator';
import { Roles } from '../../../../shared/auth/decorators/roles.decorator';
import { UserRole, User } from '../../../../shared/database/entities/user.entity';

@ApiTags('Worker - Earnings & Wallet')
@Roles(UserRole.WORKER)
@ApiBearerAuth('bearer')
@Controller('worker/earnings')
export class WorkerEarningController {
    constructor(
        private readonly earningRepo: EarningRepository,
        private readonly withdrawalRepo: WithdrawalRepository,
        private readonly workerRepo: WorkerRepository,
        private readonly payoutEngine: PayoutEngineService,
    ) { }

    @Get()
    @ApiOperation({ summary: 'Get worker earnings history' })
    async getEarnings(@CurrentUser() user: User) {
        const earnings = await this.earningRepo.findByWorker(user.id);
        return {
            success: true,
            earnings,
        };
    }

    @Get('wallet')
    @ApiOperation({ summary: 'Get worker wallet summary with minimum withdrawal threshold' })
    async getWallet(@CurrentUser() user: User) {
        const worker = await this.workerRepo.findByUserId(user.id);
        const minWithdrawalLimit = worker?.profile?.minWithdrawalLimit || this.payoutEngine.getMinWithdrawalLimit();

        const totalEarned = await this.earningRepo.getTotalEarnings(user.id);

        const totalDeducted = await this.withdrawalRepo.getTotalWithdrawalsAmount(user.id, [
            WithdrawalStatus.REQUESTED,
            WithdrawalStatus.UNDER_REVIEW,
            WithdrawalStatus.PROCESSING,
            WithdrawalStatus.PAID,
        ]);

        const pendingWithdrawals = await this.withdrawalRepo.getTotalWithdrawalsAmount(user.id, [
            WithdrawalStatus.REQUESTED,
            WithdrawalStatus.UNDER_REVIEW,
            WithdrawalStatus.PROCESSING,
        ]);

        const availableBalance = Math.max(0, totalEarned - totalDeducted);
        const isEligibleToWithdraw = availableBalance >= minWithdrawalLimit;

        const earnings = await this.earningRepo.findByWorker(user.id);
        const withdrawals = await this.withdrawalRepo.findByWorker(user.id);

        return {
            success: true,
            wallet: {
                totalEarned,
                totalDeducted,
                pendingWithdrawals,
                availableBalance,
                minWithdrawalLimit,
                isEligibleToWithdraw,
                earningsCount: earnings.length,
                withdrawalsCount: withdrawals.length,
            },
        };
    }

    @Get('balance')
    @ApiOperation({ summary: 'Get worker balance' })
    async getBalance(@CurrentUser() user: User) {
        const walletRes = await this.getWallet(user);
        return {
            success: true,
            balance: walletRes.wallet,
        };
    }

    @Post('withdraw')
    @ApiOperation({ summary: 'Request withdrawal (Enforces minimum limit and idempotency)' })
    async requestWithdrawal(
        @CurrentUser() user: User,
        @Body()
        body: {
            amount: number;
            paymentMethodId?: string;
            paymentMethod?: string;
            idempotencyKey?: string;
            metadata?: any;
        },
    ) {
        if (!body.amount || body.amount <= 0) {
            throw new BadRequestException('Withdrawal amount must be greater than 0');
        }

        const walletRes = await this.getWallet(user);
        const minLimit = walletRes.wallet.minWithdrawalLimit;

        if (body.amount < minLimit) {
            throw new BadRequestException(
                `Minimum withdrawal threshold is ₹${minLimit.toFixed(2)}. Your requested amount of ₹${body.amount.toFixed(2)} does not meet the minimum requirement.`,
            );
        }

        if (body.amount > walletRes.wallet.availableBalance) {
            throw new BadRequestException(
                `Insufficient balance. Available: ₹${walletRes.wallet.availableBalance.toFixed(2)}, Requested: ₹${body.amount.toFixed(2)}`,
            );
        }

        const withdrawalId = await this.payoutEngine.initiateWithdrawal({
            workerId: user.id,
            amount: body.amount,
            paymentMethod: body.paymentMethodId || body.paymentMethod || 'DEFAULT',
            idempotencyKey: body.idempotencyKey,
            metadata: body.metadata,
        });

        const status = await this.payoutEngine.processPayout(withdrawalId);

        return {
            success: true,
            withdrawalId,
            status,
            message: 'Withdrawal request submitted successfully',
        };
    }

    @Get('withdrawals')
    @ApiOperation({ summary: 'Get worker withdrawal history' })
    async getWithdrawals(@CurrentUser() user: User) {
        const withdrawals = await this.withdrawalRepo.findByWorker(user.id);
        return {
            success: true,
            withdrawals,
        };
    }
}
