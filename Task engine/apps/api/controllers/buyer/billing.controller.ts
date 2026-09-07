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

import { WalletService } from '../../../../shared/services/wallet.service';

@ApiTags('Buyer - Dashboard & Billing')
@Roles(UserRole.BUYER)
@ApiBearerAuth('bearer')
@Controller('buyer')
export class BuyerBillingController {
    constructor(
        private readonly orderRepo: OrderRepository,
        private readonly taskRepo: TaskRepository,
        private readonly submissionRepo: SubmissionRepository,
        private readonly walletService: WalletService,
    ) { }

    @Get('dashboard')
    @ApiOperation({ summary: 'Get buyer dashboard overview metrics' })
    async getDashboard(@CurrentUser() user: User) {
        const orders = await this.orderRepo.findByBuyer(user.id);

        let totalSpend = 0;
        let activeOrdersCount = 0;
        let completedOrdersCount = 0;
        let totalTasksCount = 0;
        let completedTasksCount = 0;
        let inProgressTasksCount = 0;
        let pendingTasksCount = 0;
        let rejectedTasksCount = 0;

        const recentCampaigns = await Promise.all(
            orders.slice(0, 10).map(async (o) => {
                const tasks = await this.taskRepo.findByOrderId(o.id);
                const completed = tasks.filter(t => this.taskRepo.matchesStatus(t.status, 'completed')).length;
                const inProg = tasks.filter(t => this.taskRepo.matchesStatus(t.status, 'assigned') || this.taskRepo.matchesStatus(t.status, 'in_progress')).length;
                const underRev = tasks.filter(t => this.taskRepo.matchesStatus(t.status, 'submitted')).length;
                const rej = tasks.filter(t => this.taskRepo.matchesStatus(t.status, 'rejected')).length;
                const pend = Math.max(0, o.totalTasksRequired - completed - inProg - underRev - rej);

                const amt = Number(o.totalAmount || (Number(o.totalTasksRequired) * Number(o.buyerUnitPrice || o.rewardPerTask || 0)));
                totalSpend += amt;

                const statusUpper = (o.status || '').toUpperCase();
                if (statusUpper === 'ACTIVE') activeOrdersCount++;
                if (statusUpper === 'COMPLETED') completedOrdersCount++;

                totalTasksCount += o.totalTasksRequired;
                completedTasksCount += completed;
                inProgressTasksCount += inProg;
                pendingTasksCount += pend;
                rejectedTasksCount += rej;

                return {
                    id: o.id,
                    name: o.title,
                    serviceType: o.requirements?.serviceName || o.serviceCode || o.taskType,
                    status: o.status,
                    totalTasks: o.totalTasksRequired,
                    completedTasks: completed,
                    pendingTasks: pend,
                    inProgressTasks: inProg,
                    amount: amt,
                    expiresIn: o.campaignExpiryDate ? `${Math.max(1, Math.round((new Date(o.campaignExpiryDate).getTime() - Date.now()) / (1000 * 3600 * 24)))} days` : '30 days',
                    createdAt: o.createdAt,
                };
            })
        );

        const overallCompletion = totalTasksCount > 0 ? (completedTasksCount / totalTasksCount) * 100 : 0;
        const wallet = await this.walletService.getWalletBalance(user.id);

        return {
            success: true,
            dashboard: {
                totalSpend,
                totalSpent: totalSpend,
                totalCampaigns: orders.length,
                totalOrdersCount: orders.length,
                activeCampaigns: activeOrdersCount,
                activeOrdersCount,
                completedCampaigns: completedOrdersCount,
                completedOrdersCount,
                pendingTasks: pendingTasksCount,
                inProgressTasks: inProgressTasksCount,
                completedTasks: completedTasksCount,
                totalTasksCompleted: completedTasksCount,
                overallCompletion,
                walletBalance: wallet.available,
                availableBalance: wallet.available,
                recentCampaigns,
            },
        };
    }

    @Get('billing/summary')
    @ApiOperation({ summary: 'Get buyer spend summary' })
    async getBillingSummary(@CurrentUser() user: User) {
        const orders = await this.orderRepo.findByBuyer(user.id);

        const committedBudget = orders.reduce(
            (acc, o) => acc + Number(o.totalAmount || (Number(o.totalTasksRequired || 0) * Number(o.buyerUnitPrice || o.rewardPerTask || 0))),
            0,
        );

        const actualSpent = orders.reduce(
            (acc, o) => acc + Number(o.tasksCompleted || 0) * Number(o.buyerUnitPrice || o.rewardPerTask || 0),
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
