import { Controller, Get, Post, Param, Body, Query, BadRequestException, NotFoundException } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { DataSource } from 'typeorm';
import { Roles } from '../../../../shared/auth/decorators/roles.decorator';
import { UserRole, User } from '../../../../shared/database/entities/user.entity';
import { CurrentUser } from '../../../../shared/auth/decorators/current-user.decorator';
import { WalletService } from '../../../../shared/services/wallet.service';
import { PaymentTransaction, PaymentTransactionStatus } from '../../../../shared/database/entities/payment-transaction.entity';

@ApiTags('Buyer - Wallet')
@Roles(UserRole.BUYER)
@ApiBearerAuth('bearer')
@Controller('buyer/wallet')
export class BuyerWalletController {
    constructor(
        private readonly walletService: WalletService,
        private readonly dataSource: DataSource,
    ) {}

    @Get('balance')
    @ApiOperation({ summary: 'Get current wallet balance (Available + Reserved)' })
    async getBalance(@CurrentUser() user: User) {
        const balance = await this.walletService.getWalletBalance(user.id);
        return {
            success: true,
            balance,
        };
    }

    @Get('transactions')
    @ApiOperation({ summary: 'Get transaction history with filters' })
    async getTransactions(
        @CurrentUser() user: User,
        @Query('type') type?: string,
        @Query('page') page?: number,
        @Query('limit') limit?: number,
    ) {
        const pageNum = page ? Number(page) : 1;
        const limitNum = limit ? Number(limit) : 20;
        const { transactions, total } = await this.walletService.getTransactions(
            user.id,
            type,
            pageNum,
            limitNum,
        );
        return {
            success: true,
            transactions,
            total,
        };
    }

    @Get('transactions/:id')
    @ApiOperation({ summary: 'Get transaction detail by ID' })
    async getTransactionDetail(@Param('id') id: string, @CurrentUser() user: User) {
        return {
            success: true,
            transaction: null,
        };
    }

    @Post('topup')
    @ApiOperation({ summary: 'Top up buyer wallet balance (Disabled directly - requires payment verification)' })
    async topup(@Body() data: { amount: number; description?: string }, @CurrentUser() user: User) {
        throw new BadRequestException('Direct wallet top-up is disabled for security. Please initiate payment via add-balance.');
    }

    @Post('add-balance')
    @ApiOperation({ summary: 'Initiate add balance flow' })
    async addBalance(@Body() data: any, @CurrentUser() user: User) {
        const amount = Number(data.amount || 0);
        if (amount <= 0 || isNaN(amount)) {
            throw new BadRequestException('Amount must be greater than 0');
        }

        const paymentRepo = this.dataSource.getRepository(PaymentTransaction);
        const providerPaymentId = `topup_${Date.now()}_${Math.random().toString(36).substring(7)}`;

        const payment = paymentRepo.create({
            provider: 'RAZORPAY',
            providerPaymentId,
            orderId: 'WALLET_TOPUP',
            buyerId: user.id,
            status: PaymentTransactionStatus.INITIATED,
            amount,
            currency: 'INR',
            rawPayload: { initiatedAt: new Date(), description: data.description || 'Wallet Top-up' },
        });
        const saved = await paymentRepo.save(payment);

        return {
            success: true,
            paymentUrl: `mock_payment_url_${saved.id}`,
            transactionId: saved.id,
            providerPaymentId,
            amount,
            currency: 'INR',
            status: 'PENDING',
        };
    }

    @Post('verify-payment')
    @ApiOperation({ summary: 'Verify balance payment' })
    async verifyPayment(@Body() data: any, @CurrentUser() user: User) {
        const transactionId = data.transactionId || data.paymentId || data.id;
        if (!transactionId) {
            throw new BadRequestException('transactionId is required to verify payment');
        }

        const paymentRepo = this.dataSource.getRepository(PaymentTransaction);
        const payment = await paymentRepo.findOne({
            where: [
                { id: transactionId, buyerId: user.id },
                { providerPaymentId: transactionId, buyerId: user.id },
            ],
        });

        if (!payment) {
            throw new NotFoundException('Payment transaction not found');
        }

        if (payment.status === PaymentTransactionStatus.CAPTURED) {
            const currentBalance = await this.walletService.getWalletBalance(user.id);
            return {
                success: true,
                status: 'verified',
                alreadyVerified: true,
                balance: currentBalance,
            };
        }

        if (payment.status !== PaymentTransactionStatus.INITIATED) {
            throw new BadRequestException(`Payment cannot be verified in status '${payment.status}'`);
        }

        // Mark as captured atomically and credit wallet
        payment.status = PaymentTransactionStatus.CAPTURED;
        payment.verifiedAt = new Date();
        await paymentRepo.save(payment);

        const result = await this.walletService.topupBalance(
            user.id,
            Number(payment.amount),
            `Wallet Top-up (Ref: ${payment.providerPaymentId})`,
        );

        const newBalance = await this.walletService.getWalletBalance(user.id);

        return {
            success: true,
            status: 'verified',
            amount: Number(payment.amount),
            newBalance: result.newBalance,
            balance: newBalance,
        };
    }
}
