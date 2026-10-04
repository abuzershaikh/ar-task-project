import {
    Controller,
    Get,
    Post,
    Delete,
    Param,
    Body,
    Query,
    NotFoundException,
    BadRequestException,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { UserRepository } from '../../../../shared/database/repositories/user.repository';
import { OrderRepository } from '../../../../shared/database/repositories/order.repository';
import { TaskRepository } from '../../../../shared/database/repositories/task.repository';
import { RatingRepository } from '../../../../shared/database/repositories/rating.repository';
import { Roles } from '../../../../shared/auth/decorators/roles.decorator';
import { UserRole, UserStatus, User } from '../../../../shared/database/entities/user.entity';
import { DataSource } from 'typeorm';

@ApiTags('Admin - Buyer Management')
@Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
@ApiBearerAuth('bearer')
@Controller('admin/buyers')
export class AdminBuyerManagementController {
    constructor(
        private readonly userRepo: UserRepository,
        private readonly orderRepo: OrderRepository,
        private readonly taskRepo: TaskRepository,
        private readonly ratingRepo: RatingRepository,
        private readonly dataSource: DataSource,
    ) { }

    @Get()
    @ApiOperation({ summary: 'List all buyers with optional status filter' })
    async listBuyers(@Query('status') statusQuery?: string) {
        const buyers = await this.dataSource
            .getRepository(User)
            .createQueryBuilder('u')
            .where('u.role = :buyerRole', { buyerRole: UserRole.BUYER })
            .orWhere('u.id IN (SELECT DISTINCT o.buyer_id FROM orders o WHERE o.buyer_id IS NOT NULL)')
            .orderBy('u.createdAt', 'DESC')
            .getMany();

        const cutoff48h = Date.now() - 48 * 60 * 60 * 1000;

        let results = await Promise.all(buyers.map(async (b) => {
            const orders = await this.orderRepo.findByBuyer(b.id);
            const activeOrders = orders.filter((o) => (o.status || '').toUpperCase() === 'ACTIVE');
            const totalSpend = orders.reduce(
                (acc, o) => acc + (Number(o.totalAmount) || (Number(o.tasksCompleted || 0) * Number(o.rewardPerTask || 0))),
                0,
            );

            const lastActive = b.lastLogin || (b as any).last_login;
            const isRecentlyActive = (lastActive && new Date(lastActive).getTime() > cutoff48h) || activeOrders.length > 0;
            const rawAccountStatus = (b.status || 'ACTIVE').toUpperCase();
            let effectiveStatus = rawAccountStatus;
            if (rawAccountStatus === 'ACTIVE') {
                effectiveStatus = isRecentlyActive ? 'ACTIVE' : 'INACTIVE';
            }

            return {
                id: b.id,
                name: (b as any).fullName || (b as any).name || b.email.split('@')[0],
                email: b.email,
                phone: b.phone || '',
                avatarUrl: (b as any).avatarUrl || (b as any).avatar_url || '',
                status: effectiveStatus,
                accountStatus: rawAccountStatus,
                activityStatus: isRecentlyActive ? 'ACTIVE' : 'INACTIVE',
                lastLogin: lastActive || null,
                totalOrders: orders.length,
                activeCampaigns: activeOrders.length,
                totalSpend,
                createdAt: b.createdAt,
            };
        }));

        if (statusQuery && statusQuery.toUpperCase() !== 'ALL') {
            const sq = statusQuery.toUpperCase();
            if (sq === 'ACTIVE') {
                results = results.filter((b) => b.status === 'ACTIVE');
            } else if (sq === 'INACTIVE') {
                results = results.filter((b) => b.status === 'INACTIVE');
            } else {
                results = results.filter((b) => b.status === sq || b.accountStatus === sq);
            }
        }

        return {
            success: true,
            buyers: results,
            total: results.length,
        };
    }

    @Get(':id')
    @ApiOperation({ summary: 'Get buyer comprehensive details' })
    async getBuyerDetail(@Param('id') buyerId: string) {
        const buyer = await this.userRepo.findById(buyerId);
        if (!buyer) {
            throw new NotFoundException('Buyer not found');
        }

        const orders = await this.orderRepo.findByBuyer(buyerId);
        const activeOrders = orders.filter((o) => (o.status || '').toUpperCase() === 'ACTIVE');
        const completedOrders = orders.filter((o) => (o.status || '').toUpperCase() === 'COMPLETED');

        const totalSpend = orders.reduce(
            (acc, o) => acc + (Number(o.totalAmount) || (Number(o.tasksCompleted || 0) * Number(o.rewardPerTask || 0))),
            0,
        );

        const formattedBuyer = {
            id: buyer.id,
            name: (buyer as any).fullName || (buyer as any).name || buyer.email.split('@')[0],
            email: buyer.email,
            phone: buyer.phone || '',
            avatarUrl: (buyer as any).avatarUrl || (buyer as any).avatar_url || '',
            status: (buyer.status || 'ACTIVE').toUpperCase(),
            totalOrders: orders.length,
            activeCampaigns: activeOrders.length,
            totalSpend,
            createdAt: buyer.createdAt,
        };

        return {
            success: true,
            buyer: formattedBuyer,
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

    @Get(':id/ratings')
    @ApiOperation({ summary: 'Get ratings and feedback submitted by buyer' })
    async getBuyerRatings(@Param('id') buyerId: string) {
        const ratings = await this.ratingRepo.findByBuyerId(buyerId);
        return { success: true, ratings, total: ratings.length };
    }

    @Post(':id/status')
    @ApiOperation({ summary: 'Update buyer status (ACTIVE, INACTIVE, SUSPENDED, BANNED)' })
    async updateStatus(
        @Param('id') buyerId: string,
        @Body() body: { status: string },
    ) {
        const buyer = await this.userRepo.findById(buyerId);
        if (!buyer) {
            throw new NotFoundException('Buyer not found');
        }

        const validStatuses = ['ACTIVE', 'INACTIVE', 'SUSPENDED', 'BANNED'];
        const targetStatus = (body.status || 'ACTIVE').toUpperCase();
        if (!validStatuses.includes(targetStatus)) {
            throw new BadRequestException(`Invalid status: ${body.status}. Must be one of ${validStatuses.join(', ')}`);
        }

        await this.userRepo.updateStatus(buyerId, targetStatus as UserStatus);
        if (targetStatus === 'ACTIVE') {
            await this.userRepo.update(buyerId, { lastLogin: new Date() });
        } else if (targetStatus === 'INACTIVE') {
            await this.userRepo.update(buyerId, { lastLogin: new Date(0) });
        }

        return {
            success: true,
            message: `Buyer status updated to ${targetStatus}`,
        };
    }

    private async performCascadeBuyerDelete(buyerId: string): Promise<boolean> {
        const buyer = await this.userRepo.findById(buyerId);
        if (!buyer) return true; // Already deleted, consider success

        // Safety check: protect Admins and Super Admins
        if (buyer.role === UserRole.ADMIN || buyer.role === UserRole.SUPER_ADMIN) {
            return false;
        }

        await this.dataSource.query('SET FOREIGN_KEY_CHECKS = 0;');
        try {
            await this.dataSource.query(`
                DELETE FROM task_submissions 
                WHERE task_id IN (SELECT id FROM tasks WHERE order_id IN (SELECT id FROM orders WHERE buyer_id = ?));
            `, [buyerId]);
            await this.dataSource.query(`
                DELETE FROM task_assignments 
                WHERE task_id IN (SELECT id FROM tasks WHERE order_id IN (SELECT id FROM orders WHERE buyer_id = ?));
            `, [buyerId]);
            await this.dataSource.query(`
                DELETE FROM tasks 
                WHERE order_id IN (SELECT id FROM orders WHERE buyer_id = ?);
            `, [buyerId]);
            await this.dataSource.query(`
                DELETE FROM order_units 
                WHERE order_id IN (SELECT id FROM orders WHERE buyer_id = ?);
            `, [buyerId]);
            await this.dataSource.query(`
                DELETE FROM task_generation_jobs 
                WHERE order_id IN (SELECT id FROM orders WHERE buyer_id = ?);
            `, [buyerId]);
            await this.dataSource.query('DELETE FROM orders WHERE buyer_id = ?;', [buyerId]);
            await this.dataSource.query('DELETE FROM wallet_transactions WHERE wallet_id IN (SELECT id FROM wallets WHERE user_id = ?);', [buyerId]);
            await this.dataSource.query('DELETE FROM wallets WHERE user_id = ?;', [buyerId]);
            await this.dataSource.query('DELETE FROM notifications WHERE user_id = ?;', [buyerId]);
            await this.dataSource.query('DELETE FROM ratings WHERE buyer_id = ?;', [buyerId]);
            await this.dataSource.query('DELETE FROM users WHERE id = ?;', [buyerId]);
        } finally {
            await this.dataSource.query('SET FOREIGN_KEY_CHECKS = 1;');
        }

        return true;
    }

    @Post('batch-delete')
    @ApiOperation({ summary: 'Batch delete multiple buyers' })
    async batchDeleteBuyers(@Body() body: { ids: string[] }) {
        if (!body.ids || !Array.isArray(body.ids) || body.ids.length === 0) {
            throw new BadRequestException('ids array is required');
        }

        let deletedCount = 0;
        for (const id of body.ids) {
            const success = await this.performCascadeBuyerDelete(id);
            if (success) deletedCount++;
        }

        return {
            success: true,
            deletedCount,
            message: `Successfully deleted ${deletedCount} buyer(s)`,
        };
    }

    @Delete(':id')
    @ApiOperation({ summary: 'Permanently delete buyer and user account' })
    async deleteBuyer(@Param('id') buyerId: string) {
        const success = await this.performCascadeBuyerDelete(buyerId);
        if (!success) {
            throw new BadRequestException('Cannot delete administrator account');
        }

        return {
            success: true,
            message: `Buyer ${buyerId} permanently deleted`,
        };
    }
}
