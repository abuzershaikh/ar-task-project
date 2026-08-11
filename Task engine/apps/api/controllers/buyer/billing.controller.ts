import {
    Controller,
    Get,
    Param,
    NotFoundException,
    ForbiddenException,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { OrderRepository } from '../../../../shared/database/repositories/order.repository';
import { TaskRepository } from '../../../../shared/database/repositories/task.repository';
import { SubmissionRepository } from '../../../../shared/database/repositories/submission.repository';
import { Roles } from '../../../../shared/auth/decorators/roles.decorator';
import { CurrentUser } from '../../../../shared/auth/decorators/current-user.decorator';
import { UserRole, User } from '../../../../shared/database/entities/user.entity';

@ApiTags('Buyer - Dashboard & Billing')
@Roles(UserRole.BUYER)
@ApiBearerAuth('bearer')
@Controller('buyer')
export class BuyerBillingController {
    constructor(
        private readonly orderRepo: OrderRepository,
        private readonly taskRepo: TaskRepository,
        private readonly submissionRepo: SubmissionRepository,
    ) { }

    @Get('dashboard')
    @ApiOperation({ summary: 'Get buyer dashboard overview metrics' })
    async getDashboard(@CurrentUser() user: User) {
        const orders = await this.orderRepo.findByBuyer(user.id);
        const activeOrders = orders.filter((o) => o.status === 'active');
        const completedOrders = orders.filter((o) => o.status === 'completed');

        const totalSpent = orders.reduce(
            (acc, o) => acc + Number(o.tasksCompleted || 0) * Number(o.rewardPerTask || 0),
            0,
        );

        const totalTasksCompleted = orders.reduce((acc, o) => acc + Number(o.tasksCompleted || 0), 0);

        return {
            success: true,
            dashboard: {
                totalOrdersCount: orders.length,
                activeOrdersCount: activeOrders.length,
                completedOrdersCount: completedOrders.length,
                totalSpent,
                totalTasksCompleted,
            },
        };
    }

    @Get('billing/summary')
    @ApiOperation({ summary: 'Get buyer spend summary' })
    async getBillingSummary(@CurrentUser() user: User) {
        const orders = await this.orderRepo.findByBuyer(user.id);

        const committedBudget = orders.reduce(
            (acc, o) => acc + Number(o.totalTasksRequired || 0) * Number(o.rewardPerTask || 0),
            0,
        );

        const actualSpent = orders.reduce(
            (acc, o) => acc + Number(o.tasksCompleted || 0) * Number(o.rewardPerTask || 0),
            0,
        );

        return {
            success: true,
            billing: {
                totalOrders: orders.length,
                committedBudget,
                actualSpent,
                remainingBudget: Math.max(0, committedBudget - actualSpent),
            },
        };
    }

    @Get('orders/:id/invoice')
    @ApiOperation({ summary: 'Get itemized order invoice' })
    async getOrderInvoice(@Param('id') orderId: string, @CurrentUser() user: User) {
        const order = await this.orderRepo.findById(orderId);
        if (!order) {
            throw new NotFoundException('Order not found');
        }

        if (order.buyerId !== user.id) {
            throw new ForbiddenException('You do not have access to this order');
        }

        const totalCommitted = Number(order.totalTasksRequired) * Number(order.rewardPerTask);
        const totalCompletedAmount = Number(order.tasksCompleted) * Number(order.rewardPerTask);

        return {
            success: true,
            invoice: {
                invoiceNumber: `INV-${order.id.slice(0, 8).toUpperCase()}`,
                orderId: order.id,
                title: order.title,
                createdAt: order.createdAt,
                unitPrice: order.rewardPerTask,
                totalTasksRequired: order.totalTasksRequired,
                tasksCompleted: order.tasksCompleted,
                subtotal: totalCompletedAmount,
                totalCommitted,
                status: order.status,
            },
        };
    }
}
