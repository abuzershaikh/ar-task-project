import {
    Controller,
    Get,
    Post,
    Param,
    Body,
    NotFoundException,
    ForbiddenException,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { OrderRepository } from '../../../../shared/database/repositories/order.repository';
import { Roles } from '../../../../shared/auth/decorators/roles.decorator';
import { CurrentUser } from '../../../../shared/auth/decorators/current-user.decorator';
import { UserRole, User } from '../../../../shared/database/entities/user.entity';

@ApiTags('Buyer - Payments')
@Roles(UserRole.BUYER)
@ApiBearerAuth('bearer')
@Controller('buyer')
export class BuyerPaymentController {
    constructor(private readonly orderRepo: OrderRepository) { }

    @Get('payments')
    @ApiOperation({ summary: 'List all buyer payment transactions' })
    async getPayments(@CurrentUser() user: User) {
        const orders = await this.orderRepo.findByBuyer(user.id);
        const payments = orders.map((o) => ({
            paymentId: `PAY-${o.id.slice(0, 8).toUpperCase()}`,
            orderId: o.id,
            orderTitle: o.title,
            amount: o.totalAmount || Number(o.totalTasksRequired) * Number(o.rewardPerTask),
            status: o.status === 'PAYMENT_PENDING' ? 'PENDING' : 'SUCCESS',
            paymentMethod: 'ONLINE_GATEWAY',
            createdAt: o.createdAt,
        }));

        return {
            success: true,
            payments,
            total: payments.length,
        };
    }

    @Get('payments/:id')
    @ApiOperation({ summary: 'Get payment transaction details' })
    async getPaymentById(@Param('id') paymentId: string, @CurrentUser() user: User) {
        return {
            success: true,
            payment: {
                paymentId,
                amount: 5000.0,
                currency: 'INR',
                status: 'CAPTURED',
                provider: 'RAZORPAY',
                buyerId: user.id,
                createdAt: new Date(),
            },
        };
    }

    @Post('orders/:id/payment')
    @ApiOperation({ summary: 'Initiate order payment session with payment gateway' })
    async initiatePayment(
        @Param('id') orderId: string,
        @Body() body: { gateway?: string },
        @CurrentUser() user: User,
    ) {
        const order = await this.orderRepo.findById(orderId);
        if (!order || order.buyerId !== user.id) {
            throw new NotFoundException('Order not found or access denied');
        }

        const gateway = body.gateway || 'RAZORPAY';
        const totalAmount = order.totalAmount || Number(order.totalTasksRequired) * Number(order.rewardPerTask);

        return {
            success: true,
            paymentSession: {
                orderId: order.id,
                gateway,
                amount: totalAmount,
                currency: 'INR',
                gatewayOrderId: `pay_order_${Date.now()}`,
                key: 'rzp_test_mock_key',
            },
            message: 'Payment session initiated',
        };
    }

    @Get('orders/:id/payment-status')
    @ApiOperation({ summary: 'Get payment status for order' })
    async getPaymentStatus(@Param('id') orderId: string, @CurrentUser() user: User) {
        const order = await this.orderRepo.findById(orderId);
        if (!order || order.buyerId !== user.id) {
            throw new NotFoundException('Order not found or access denied');
        }

        return {
            success: true,
            orderId: order.id,
            paymentStatus: order.status === 'PAYMENT_PENDING' ? 'PENDING' : 'PAID',
            totalAmount: order.totalAmount || Number(order.totalTasksRequired) * Number(order.rewardPerTask),
        };
    }
}
