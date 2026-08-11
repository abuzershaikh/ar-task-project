import { Controller, Post, Param, Body, Headers } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { Public } from '../../../../shared/auth/decorators/public.decorator';
import { OrderStateMachineService } from '../../../../shared/services/order-state-machine.service';
import { PaymentTransactionRepository } from '../../../../shared/database/repositories/payment-transaction.repository';
import { OrderRepository } from '../../../../shared/database/repositories/order.repository';
import { PaymentTransactionStatus } from '../../../../shared/database/entities/payment-transaction.entity';

@ApiTags('Webhooks')
@Controller('webhooks')
export class WebhookController {
    constructor(
        private readonly orderStateMachine: OrderStateMachineService,
        private readonly paymentTxRepo: PaymentTransactionRepository,
        private readonly orderRepo: OrderRepository,
    ) { }

    @Public()
    @Post('payment/:provider')
    @ApiOperation({ summary: 'Receive payment gateway webhooks (Razorpay / Stripe / Cashfree)' })
    async handlePaymentWebhook(
        @Param('provider') providerRaw: string,
        @Body() body: any,
        @Headers('x-razorpay-signature') razorpaySignature?: string,
        @Headers('stripe-signature') stripeSignature?: string,
    ) {
        const provider = providerRaw.toUpperCase();
        const event = body.event || body.type || 'payment.captured';
        const orderId = body.payload?.payment?.entity?.notes?.orderId || body.orderId;
        const transactionId = body.payload?.payment?.entity?.id || body.paymentId || `txn_${Date.now()}`;
        const eventId = body.event_id || body.id || null;
        const amount = Number(body.payload?.payment?.entity?.amount || body.amount || 0) / 100 || 0;

        if (!orderId) {
            return { received: true, status: 'ignored_no_order_id' };
        }

        // Protection Pillar 4: Webhook Idempotency Check
        const existingTx = await this.paymentTxRepo.findByProviderPaymentId(provider, transactionId);
        if (existingTx && existingTx.status === PaymentTransactionStatus.CAPTURED) {
            return {
                received: true,
                provider,
                event,
                status: 'already_processed',
                orderId,
                transactionId,
            };
        }

        const order = await this.orderRepo.findById(orderId);
        const buyerId = order ? order.buyerId : 'system';

        // Record PaymentTransaction in DB
        await this.paymentTxRepo.create({
            provider,
            providerPaymentId: transactionId,
            providerEventId: eventId,
            orderId,
            buyerId,
            status: PaymentTransactionStatus.CAPTURED,
            amount: amount || (order ? Number(order.totalAmount) : 0),
            currency: 'INR',
            rawPayload: body,
            verifiedAt: new Date(),
        });

        // Trigger Order State Machine transition to ACTIVE
        // OrderStateMachine handles status guard, creates TaskGenerationJob, and dispatches 'order.activated' event
        await this.orderStateMachine.transitionToActive(orderId, transactionId);

        return {
            received: true,
            provider,
            event,
            status: 'processed',
            orderId,
            transactionId,
        };
    }
}
