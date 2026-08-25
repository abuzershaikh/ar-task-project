import {
    Controller,
    Get,
    Post,
    Param,
    Body,
    Query,
    BadRequestException,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { Roles } from '../../../../shared/auth/decorators/roles.decorator';
import { UserRole } from '../../../../shared/database/entities/user.entity';
import { WalletService } from '../../../../shared/services/wallet.service';

@ApiTags('Admin - Wallet & Topup Management')
@Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
@ApiBearerAuth('bearer')
@Controller('admin/wallet')
export class AdminWalletController {
    constructor(private readonly walletService: WalletService) {}

    @Get('buyers')
    @ApiOperation({ summary: 'List all buyers with live wallet balances and search' })
    @ApiQuery({ name: 'search', required: false })
    async getBuyersWithWallet(@Query('search') search?: string) {
        return this.walletService.getAllBuyersWithWallet(search);
    }

    @Get('buyers/:buyerId/transactions')
    @ApiOperation({ summary: 'Get transactions for a specific buyer' })
    @ApiQuery({ name: 'limit', required: false })
    async getBuyerTransactions(
        @Param('buyerId') buyerId: string,
        @Query('limit') limit?: number,
    ) {
        return this.walletService.getBuyerTransactions(buyerId, limit ? Number(limit) : 50);
    }

    @Post('topup')
    @ApiOperation({ summary: 'Credit or Debit balance for a buyer' })
    async topupBuyer(
        @Body()
        data: {
            buyerId: string;
            amount: number;
            type?: 'CREDIT' | 'DEBIT';
            notes?: string;
        },
    ) {
        if (!data.buyerId) {
            throw new BadRequestException('buyerId is required');
        }
        if (!data.amount || Number(data.amount) <= 0) {
            throw new BadRequestException('Amount must be greater than 0');
        }

        const type = data.type === 'DEBIT' ? 'DEBIT' : 'CREDIT';
        const result = await this.walletService.adminTopup(
            data.buyerId,
            Number(data.amount),
            type,
            data.notes,
        );

        return {
            success: true,
            message: `Successfully ${type === 'CREDIT' ? 'credited' : 'debited'} ₹${Number(data.amount).toFixed(2)} for buyer.`,
            data: result,
        };
    }
}
