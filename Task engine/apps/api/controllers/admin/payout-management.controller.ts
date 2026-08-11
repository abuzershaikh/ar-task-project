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
        return {
            success: true,
            withdrawals,
            count: withdrawals.length,
        };
    }

    @Post(':withdrawalId/process')
    @ApiOperation({ summary: 'Mark withdrawal as PROCESSING' })
    async processPayout(@Param('withdrawalId') withdrawalId: string) {
        const withdrawal = await this.withdrawalRepo.findById(withdrawalId);
        if (!withdrawal) {
            throw new NotFoundException('Withdrawal not found');
        }

        const updated = await this.withdrawalRepo.update(withdrawalId, {
            status: WithdrawalStatus.PROCESSING,
            processedAt: new Date(),
        });

        return {
            success: true,
            withdrawal: updated,
            message: 'Withdrawal status set to PROCESSING',
        };
    }

    @Post(':withdrawalId/mark-paid')
    @ApiOperation({ summary: 'Mark withdrawal as PAID with transaction reference' })
    async markPaid(
        @Param('withdrawalId') withdrawalId: string,
        @Body() body: { transactionId?: string; providerReference?: string },
    ) {
        const withdrawal = await this.withdrawalRepo.findById(withdrawalId);
        if (!withdrawal) {
            throw new NotFoundException('Withdrawal not found');
        }

        const updated = await this.withdrawalRepo.update(withdrawalId, {
            status: WithdrawalStatus.PAID,
            paidAt: new Date(),
            transactionId: body.transactionId,
            providerReference: body.providerReference,
        });

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
        const withdrawal = await this.withdrawalRepo.findById(withdrawalId);
        if (!withdrawal) {
            throw new NotFoundException('Withdrawal not found');
        }

        const updated = await this.withdrawalRepo.update(withdrawalId, {
            status: WithdrawalStatus.REJECTED,
            rejectionReason: body.reason || 'Admin rejected payout',
        });

        return {
            success: true,
            withdrawal: updated,
            message: 'Withdrawal rejected and balance released',
        };
    }
}
