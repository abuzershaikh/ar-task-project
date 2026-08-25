import { Controller, Get, Post, Param, Body, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { Roles } from '../../../../shared/auth/decorators/roles.decorator';
import { UserRole, User } from '../../../../shared/database/entities/user.entity';
import { CurrentUser } from '../../../../shared/auth/decorators/current-user.decorator';
import { WalletService } from '../../../../shared/services/wallet.service';

@ApiTags('Buyer - Wallet')
@Roles(UserRole.BUYER)
@ApiBearerAuth('bearer')
@Controller('buyer/wallet')
export class BuyerWalletController {
    constructor(private readonly walletService: WalletService) {}

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
        const { transactions, total } = await this.walletService.getTransactions(user.id, limit || 20);
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
    @ApiOperation({ summary: 'Top up buyer wallet balance' })
    async topup(@Body() data: { amount: number; description?: string }, @CurrentUser() user: User) {
        const result = await this.walletService.topupBalance(
            user.id,
            Number(data.amount || 0),
            data.description || 'Wallet Top-up',
        );
        return {
            success: true,
            message: `Successfully topped up ₹${Number(data.amount || 0).toFixed(2)}`,
            ...result,
        };
    }

    @Post('add-balance')
    @ApiOperation({ summary: 'Initiate add balance flow' })
    async addBalance(@Body() data: any, @CurrentUser() user: User) {
        const result = await this.walletService.topupBalance(user.id, Number(data.amount || 0));
        return {
            success: true,
            paymentUrl: `mock_payment_url_${result.transaction?.id}`,
            transactionId: result.transaction?.id,
            newBalance: result.newBalance,
        };
    }

    @Post('verify-payment')
    @ApiOperation({ summary: 'Verify balance payment' })
    async verifyPayment(@Body() data: any, @CurrentUser() user: User) {
        return {
            success: true,
            status: 'verified',
        };
    }
}
