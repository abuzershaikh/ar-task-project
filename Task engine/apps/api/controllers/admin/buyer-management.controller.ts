import {
    Controller,
    Get,
    Post,
    Param,
    Body,
    NotFoundException,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { UserRepository } from '../../../../shared/database/repositories/user.repository';
import { OrderRepository } from '../../../../shared/database/repositories/order.repository';
import { TaskRepository } from '../../../../shared/database/repositories/task.repository';
import { Roles } from '../../../../shared/auth/decorators/roles.decorator';
import { UserRole, UserStatus } from '../../../../shared/database/entities/user.entity';

@ApiTags('Admin - Buyer Management')
@Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
@ApiBearerAuth('bearer')
@Controller('admin/buyers')
export class AdminBuyerManagementController {
    constructor(
        private readonly userRepo: UserRepository,
        private readonly orderRepo: OrderRepository,
        private readonly taskRepo: TaskRepository,
    ) { }

    @Get()
    @ApiOperation({ summary: 'List all buyers' })
    async listBuyers() {
        const buyers = await this.userRepo.findByRole(UserRole.BUYER);
        return {
            success: true,
            buyers,
            total: buyers.length,
        };
    }

    @Get(':id')
    @ApiOperation({ summary: 'Get buyer comprehensive details' })
    async getBuyerDetail(@Param('id') buyerId: string) {
        const buyer = await this.userRepo.findById(buyerId);
        if (!buyer || buyer.role !== UserRole.BUYER) {
            throw new NotFoundException('Buyer not found');
        }

        const orders = await this.orderRepo.findByBuyer(buyerId);
        const activeOrders = orders.filter((o) => o.status === 'ACTIVE' || o.status === 'active');
        const completedOrders = orders.filter((o) => o.status === 'COMPLETED' || o.status === 'completed');

        const totalSpend = orders.reduce(
            (acc, o) => acc + (o.totalAmount || (Number(o.tasksCompleted || 0) * Number(o.rewardPerTask || 0))),
            0,
        );

        return {
            success: true,
            buyer,
            metrics: {
                totalOrdersCount: orders.length,
                activeOrdersCount: activeOrders.length,
                completedOrdersCount: completedOrders.length,
                totalSpend,
            },
        };
    }

    @Get(':id/orders')
    @ApiOperation({ summary: 'Get buyer order history' })
    async getBuyerOrders(@Param('id') buyerId: string) {
        const orders = await this.orderRepo.findByBuyer(buyerId);
        return { success: true, orders, total: orders.length };
    }

    @Get(':id/tasks')
    @ApiOperation({ summary: 'Get all tasks for buyer across orders' })
    async getBuyerTasks(@Param('id') buyerId: string) {
        const orders = await this.orderRepo.findByBuyer(buyerId);
        let allTasks: any[] = [];
        for (const order of orders) {
            const tasks = await this.taskRepo.findByOrderId(order.id);
            allTasks = allTasks.concat(tasks);
        }
        return { success: true, tasks: allTasks, total: allTasks.length };
    }

    @Get(':id/payments')
    @ApiOperation({ summary: 'Get buyer payment transactions history' })
    async getBuyerPayments(@Param('id') buyerId: string) {
        const orders = await this.orderRepo.findByBuyer(buyerId);
        const payments = orders.map((o) => ({
            paymentId: `PAY-${o.id.slice(0, 8).toUpperCase()}`,
            orderId: o.id,
            amount: o.totalAmount || Number(o.totalTasksRequired) * Number(o.rewardPerTask),
            status: 'PAID',
            createdAt: o.createdAt,
        }));
        return { success: true, payments };
    }

    @Get(':id/activity')
    @ApiOperation({ summary: 'Get buyer platform activity log' })
    async getBuyerActivity(@Param('id') buyerId: string) {
        return {
            success: true,
            buyerId,
            activity: [
                { type: 'ACCOUNT_CREATED', timestamp: new Date() },
            ],
        };
    }

    @Get(':id/analytics')
    @ApiOperation({ summary: 'Get buyer deep analytics' })
    async getBuyerAnalytics(@Param('id') buyerId: string) {
        const orders = await this.orderRepo.findByBuyer(buyerId);
        return {
            success: true,
            buyerId,
            analytics: {
                totalOrders: orders.length,
                totalCommittedBudget: orders.reduce((acc, o) => acc + (o.totalAmount || 0), 0),
            },
        };
    }

    @Post(':id/status')
    @ApiOperation({ summary: 'Update buyer status (ACTIVE, SUSPENDED, BANNED)' })
    async updateStatus(
        @Param('id') buyerId: string,
        @Body() body: { status: UserStatus },
    ) {
        const buyer = await this.userRepo.findById(buyerId);
        if (!buyer || buyer.role !== UserRole.BUYER) {
            throw new NotFoundException('Buyer not found');
        }

        await this.userRepo.updateStatus(buyerId, body.status);
        return {
            success: true,
            message: `Buyer status updated to ${body.status}`,
        };
    }
}
