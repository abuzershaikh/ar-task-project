import { Controller, Get, Post, Param, Body, Query, BadRequestException, NotFoundException } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { DataSource } from 'typeorm';
import * as crypto from 'crypto';
import * as https from 'https';
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

    /**
     * Helper to create an order directly with Razorpay API using Basic Auth
     */
    private async createRazorpayOrder(amountInPaise: number, receipt: string, notes: any = {}): Promise<any> {
        const keyId = process.env.RAZORPAY_KEY_ID || 'rzp_live_TI2wdFKYDJdAxY';
        const keySecret = process.env.RAZORPAY_KEY_SECRET || '0pNQOQBRWxmtdE8mPVLlvYfi';
        const auth = Buffer.from(`${keyId}:${keySecret}`).toString('base64');

        const postData = JSON.stringify({
            amount: amountInPaise,
            currency: 'INR',
            receipt,
            notes,
        });

        return new Promise((resolve, reject) => {
            const req = https.request('https://api.razorpay.com/v1/orders', {
                method: 'POST',
                headers: {
                    'Authorization': `Basic ${auth}`,
                    'Content-Type': 'application/json',
                    'Content-Length': Buffer.byteLength(postData),
                },
            }, (res) => {
                let data = '';
                res.on('data', (chunk) => data += chunk);
                res.on('end', () => {
                    try {
                        const parsed = JSON.parse(data);
                        if (res.statusCode && res.statusCode >= 200 && res.statusCode < 300) {
                            resolve(parsed);
                        } else {
                            reject(new Error(parsed.error?.description || `Razorpay order creation failed (HTTP ${res.statusCode})`));
                        }
                    } catch (e) {
                        reject(new Error('Invalid response received from Razorpay'));
                    }
                });
            });

            req.on('error', (err) => reject(err));
            req.write(postData);
            req.end();
        });
    }

    /**
     * Helper to verify Razorpay HMAC-SHA256 signature
     */
    private verifyRazorpaySignature(orderId: string, paymentId: string, signature: string): boolean {
        const keySecret = process.env.RAZORPAY_KEY_SECRET || '0pNQOQBRWxmtdE8mPVLlvYfi';
        const expectedSignature = crypto
            .createHmac('sha256', keySecret)
            .update(`${orderId}|${paymentId}`)
            .digest('hex');
        return expectedSignature === signature;
    }

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
        throw new BadRequestException('Direct wallet top-up is disabled for security. Please initiate payment via add-balance or razorpay-order.');
    }

    /**
     * Create live Razorpay Order for Flutter / Web Checkout
     */
    @Post('razorpay-order')
    @ApiOperation({ summary: 'Create a live Razorpay order for wallet top-up' })
    async createRazorpayOrderEndpoint(@Body() data: any, @CurrentUser() user: User) {
        const amount = Number(data.amount || 0);
        if (amount < 1 || isNaN(amount)) {
            throw new BadRequestException('Amount must be at least ₹1.00');
        }

        const amountInPaise = Math.round(amount * 100);
        const receipt = `rcpt_${Date.now()}_${Math.random().toString(36).substring(7)}`;

        try {
            const rzpOrder = await this.createRazorpayOrder(amountInPaise, receipt, {
                buyerId: user.id,
                buyerEmail: user.email || '',
                description: data.description || 'Wallet Top-up',
            });

            const paymentRepo = this.dataSource.getRepository(PaymentTransaction);
            const payment = paymentRepo.create({
                provider: 'RAZORPAY',
                providerPaymentId: rzpOrder.id,
                orderId: 'WALLET_TOPUP',
                buyerId: user.id,
                status: PaymentTransactionStatus.INITIATED,
                amount,
                currency: 'INR',
                rawPayload: {
                    razorpayOrderId: rzpOrder.id,
                    receipt: rzpOrder.receipt,
                    description: data.description || 'Wallet Top-up',
                    createdAt: new Date(),
                },
            });
            const saved = await paymentRepo.save(payment);

            const keyId = process.env.RAZORPAY_KEY_ID || 'rzp_live_TI2wdFKYDJdAxY';
            const companyName = process.env.RAZORPAY_COMPANY_NAME || 'Ishyan Technologies';

            return {
                success: true,
                orderId: rzpOrder.id,
                amount,
                amountInPaise,
                currency: 'INR',
                keyId,
                companyName,
                transactionId: saved.id,
            };
        } catch (error: any) {
            throw new BadRequestException(error.message || 'Failed to create Razorpay order');
        }
    }

    /**
     * Verify Razorpay Payment Signature and atomically credit Buyer Wallet
     */
    @Post('razorpay-verify')
    @ApiOperation({ summary: 'Verify Razorpay payment signature and atomically credit wallet' })
    async verifyRazorpayPaymentEndpoint(@Body() data: any, @CurrentUser() user: User) {
        const orderId = data.orderId || data.razorpay_order_id;
        const paymentId = data.paymentId || data.razorpay_payment_id;
        const signature = data.signature || data.razorpay_signature;

        if (!orderId || !paymentId || !signature) {
            throw new BadRequestException('orderId, paymentId, and signature are required for verification');
        }

        const isValid = this.verifyRazorpaySignature(orderId, paymentId, signature);
        if (!isValid) {
            throw new BadRequestException('Invalid Razorpay signature. Verification failed.');
        }

        const paymentRepo = this.dataSource.getRepository(PaymentTransaction);

        // Check if already captured by paymentId
        let existingCaptured = await paymentRepo.findOne({
            where: { providerPaymentId: paymentId, buyerId: user.id, status: PaymentTransactionStatus.CAPTURED },
        });

        if (existingCaptured) {
            const currentBalance = await this.walletService.getWalletBalance(user.id);
            return {
                success: true,
                verified: true,
                alreadyVerified: true,
                amount: Number(existingCaptured.amount),
                balance: currentBalance,
                newBalance: currentBalance.available,
                message: 'Payment was already verified and credited',
            };
        }

        // Find the initiated transaction by orderId
        let payment = await paymentRepo.findOne({
            where: { providerPaymentId: orderId, buyerId: user.id },
        });

        if (!payment && data.transactionId) {
            payment = await paymentRepo.findOne({
                where: { id: data.transactionId, buyerId: user.id },
            });
        }

        if (!payment) {
            const allInitiated = await paymentRepo.find({
                where: { buyerId: user.id, status: PaymentTransactionStatus.INITIATED },
                order: { createdAt: 'DESC' },
                take: 20,
            });
            payment = allInitiated.find(p => p.rawPayload?.razorpayOrderId === orderId) || null;
        }

        const amountToCredit = payment ? Number(payment.amount) : Number(data.amount || 0);
        if (amountToCredit <= 0) {
            throw new BadRequestException('Invalid payment amount. Cannot credit wallet.');
        }

        if (payment) {
            payment.providerPaymentId = paymentId;
            payment.status = PaymentTransactionStatus.CAPTURED;
            payment.verifiedAt = new Date();
            payment.rawPayload = {
                ...(payment.rawPayload || {}),
                razorpayOrderId: orderId,
                razorpayPaymentId: paymentId,
                signature,
                verifiedAt: new Date(),
            };
            await paymentRepo.save(payment);
        } else {
            payment = paymentRepo.create({
                provider: 'RAZORPAY',
                providerPaymentId: paymentId,
                orderId: 'WALLET_TOPUP',
                buyerId: user.id,
                status: PaymentTransactionStatus.CAPTURED,
                amount: amountToCredit,
                currency: 'INR',
                verifiedAt: new Date(),
                rawPayload: { razorpayOrderId: orderId, razorpayPaymentId: paymentId, signature, verifiedAt: new Date() },
            });
            await paymentRepo.save(payment);
        }

        // Atomically credit wallet
        const result = await this.walletService.topupBalance(
            user.id,
            amountToCredit,
            `Wallet Top-up (Razorpay: ${paymentId})`,
        );

        const currentBalance = await this.walletService.getWalletBalance(user.id);

        return {
            success: true,
            verified: true,
            amount: amountToCredit,
            paymentId,
            orderId,
            newBalance: result.newBalance,
            balance: currentBalance,
            message: 'Payment verified and wallet credited successfully',
        };
    }

    /**
     * Backward-compatible add-balance flow
     */
    @Post('add-balance')
    @ApiOperation({ summary: 'Initiate add balance flow' })
    async addBalance(@Body() data: any, @CurrentUser() user: User) {
        const amount = Number(data.amount || 0);
        if (amount <= 0 || isNaN(amount)) {
            throw new BadRequestException('Amount must be greater than 0');
        }

        // Automatically trigger live Razorpay order
        return this.createRazorpayOrderEndpoint(data, user);
    }

    /**
     * Backward-compatible verify-payment flow
     */
    @Post('verify-payment')
    @ApiOperation({ summary: 'Verify balance payment' })
    async verifyPayment(@Body() data: any, @CurrentUser() user: User) {
        if (data.signature || data.razorpay_signature) {
            return this.verifyRazorpayPaymentEndpoint(data, user);
        }

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
                newBalance: currentBalance.available,
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

