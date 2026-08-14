import { Controller, Get, Post, Body } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { Public } from '../../../../shared/auth/decorators/public.decorator';

@ApiTags('Health')
@Controller('health')
export class HealthController {
    constructor(private readonly eventEmitter: EventEmitter2) {}

    @Public()
    @Get()
    @ApiOperation({ summary: 'Health check endpoint' })
    check() {
        return {
            status: 'ok',
            timestamp: new Date().toISOString(),
            uptime: process.uptime(),
        };
    }

    @Public()
    @Post('test-queue')
    @ApiOperation({ summary: 'Trigger test order.activated event to test end-to-end Bull Redis Queue processing' })
    async testQueue(@Body() body: { orderId?: string; count?: number }) {
        if (process.env.NODE_ENV === 'production' && process.env.ENABLE_TEST_ENDPOINTS !== 'true') {
            return {
                success: false,
                message: 'Test endpoint disabled in production mode. Set ENABLE_TEST_ENDPOINTS=true to enable.',
            };
        }

        const testOrderId = body.orderId || `TEST_ORDER_${Date.now()}`;
        const count = body.count || 3;

        // Emit order.activated event which triggers OrderActivatedListener -> Bull Queue -> TaskQueueProcessor -> MySQL
        this.eventEmitter.emit('order.activated', {
            orderId: testOrderId,
            buyerId: 'test-buyer-id',
            serviceCode: 'YOUTUBE_SUBSCRIBE',
            totalTasksRequired: count,
            workerRewardSnapshot: 10,
            activatedAt: new Date(),
        });

        return {
            success: true,
            message: `Event 'order.activated' emitted for Order ${testOrderId}. Enqueued to Redis Bull Queue.`,
            orderId: testOrderId,
            count,
        };
    }
}
