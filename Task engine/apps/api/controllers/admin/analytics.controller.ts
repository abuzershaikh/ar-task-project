import { Controller, Get, Query } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { TaskRepository } from '../../../../shared/database/repositories/task.repository';
import { WorkerRepository } from '../../../../shared/database/repositories/worker.repository';
import { OrderRepository } from '../../../../shared/database/repositories/order.repository';
import { Roles } from '../../../../shared/auth/decorators/roles.decorator';
import { UserRole } from '../../../../shared/database/entities/user.entity';

/**
 * Admin Analytics APIs
 */
@Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
@Controller('admin/analytics')
export class AdminAnalyticsController {
    constructor(
        private readonly taskRepo: TaskRepository,
        private readonly workerRepo: WorkerRepository,
        private readonly orderRepo: OrderRepository,
        private readonly dataSource: DataSource,
    ) { }

    @Get('overview')
    async getOverview() {
        const activeOrders = await this.orderRepo.findActiveOrders();
        const activeWorkers = await this.workerRepo.findActiveWorkers();

        const totalTasks = await this.taskRepo.countByStatus('completed');
        const pendingTasks = await this.taskRepo.countByStatus('pending');

        return {
            success: true,
            overview: {
                totalOrders: activeOrders.length,
                totalWorkers: activeWorkers.length,
                totalTasks,
                pendingTasks,
                completedTasks: totalTasks,
            },
        };
    }

    @Get('tasks')
    async getTaskAnalytics(@Query('period') period: string) {
        return {
            success: true,
            analytics: {
                created: 0,
                assigned: 0,
                completed: 0,
                rejected: 0,
            },
        };
    }

    @Get('workers')
    async getWorkerAnalytics() {
        const workers = await this.workerRepo.findActiveWorkers();

        return {
            success: true,
            analytics: {
                total: workers.length,
                active: workers.filter((worker) => worker.status?.toLowerCase() === 'active').length,
                kycPending: workers.filter((worker) => worker.kycStatus?.toLowerCase() === 'pending').length,
                kycApproved: workers.filter((worker) => worker.kycStatus?.toLowerCase() === 'approved').length,
            },
        };
    }

    @Get('revenue')
    async getRevenueAnalytics() {
        try {
            const [grossRow] = await this.dataSource.query(
                `SELECT COALESCE(SUM(total_amount), 0) as grossVolume,
                        COALESCE(SUM(tasks_completed * platform_margin_snapshot), 0) as realizedMargin,
                        COALESCE(SUM(total_tasks_required * platform_margin_snapshot), 0) as projectedMargin
                 FROM orders WHERE status != 'CANCELLED'`,
            );

            const [depositsRow] = await this.dataSource.query(
                `SELECT COALESCE(SUM(amount), 0) as totalDeposits
                 FROM wallet_transactions
                 WHERE type IN ('CREDIT', 'DEPOSIT') AND status = 'COMPLETED'`,
            );

            const [payoutsRow] = await this.dataSource.query(
                `SELECT COALESCE(SUM(amount), 0) as totalPayouts
                 FROM withdrawals
                 WHERE status IN ('COMPLETED', 'APPROVED', 'PAID')`,
            );

            const [walletPoolRow] = await this.dataSource.query(
                `SELECT COALESCE(SUM(available_balance), 0) as walletPool FROM wallets`,
            );

            const ledgerItems = await this.dataSource.query(
                `SELECT 
                    wt.id,
                    wt.type,
                    CAST(wt.amount AS DECIMAL(12,2)) as amount,
                    CAST(wt.balance_after AS DECIMAL(12,2)) as balanceAfter,
                    wt.description,
                    wt.status,
                    wt.created_at as createdAt,
                    wt.reference_id as referenceId,
                    wt.reference_type as referenceType,
                    u.id as userId,
                    u.full_name as userName,
                    u.email as userEmail,
                    u.role as userRole
                FROM wallet_transactions wt
                LEFT JOIN wallets w ON wt.wallet_id = w.id
                LEFT JOIN users u ON w.user_id = u.id
                ORDER BY wt.created_at DESC
                LIMIT 100`,
            );

            const grossPlatformVolume = parseFloat(grossRow?.grossVolume || 0);
            const platformNetMargin = parseFloat(grossRow?.realizedMargin || 0);
            const projectedMargin = parseFloat(grossRow?.projectedMargin || 0);
            const totalBuyerDeposits = parseFloat(depositsRow?.totalDeposits || 0);
            const totalWorkerPayouts = parseFloat(payoutsRow?.totalPayouts || 0);
            const walletPoolBalance = parseFloat(walletPoolRow?.walletPool || 0);

            return {
                success: true,
                grossPlatformVolume,
                platformNetMargin,
                projectedMargin,
                totalBuyerDeposits,
                totalWorkerPayouts,
                walletPoolBalance,
                revenue: {
                    total: grossPlatformVolume,
                    thisMonth: grossPlatformVolume,
                    lastMonth: 0,
                },
                ledger: ledgerItems.map((item: any) => ({
                    id: item.id,
                    type: item.type,
                    amount: parseFloat(item.amount || 0),
                    balanceAfter: parseFloat(item.balanceAfter || 0),
                    title: item.description || (item.type === 'CREDIT' ? 'Wallet Deposit / Credit' : 'Campaign Order Payment'),
                    description: item.description || '',
                    status: item.status || 'COMPLETED',
                    createdAt: item.createdAt,
                    date: item.createdAt,
                    userName: item.userName || (item.userEmail ? item.userEmail.split('@')[0] : 'Platform User'),
                    userEmail: item.userEmail || '',
                    userRole: item.userRole || '',
                    referenceId: item.referenceId || item.id,
                })),
            };
        } catch (error: any) {
            return {
                success: false,
                error: error?.message || 'Failed to fetch revenue analytics',
                grossPlatformVolume: 0,
                platformNetMargin: 0,
                projectedMargin: 0,
                totalBuyerDeposits: 0,
                totalWorkerPayouts: 0,
                walletPoolBalance: 0,
                revenue: { total: 0, thisMonth: 0, lastMonth: 0 },
                ledger: [],
            };
        }
    }

    @Get('ledger')
    async getLedger(
        @Query('type') type?: string,
        @Query('search') search?: string,
        @Query('page') page?: any,
        @Query('limit') limit?: any,
    ) {
        try {
            const safePage = Math.max(1, parseInt(String(page || 1), 10) || 1);
            const safeLimit = Math.max(1, Math.min(100, parseInt(String(limit || 50), 10) || 50));
            const offset = (safePage - 1) * safeLimit;

            const whereClauses: string[] = [];
            const params: any[] = [];

            if (type && type.toUpperCase() !== 'ALL') {
                const upper = type.toUpperCase();
                if (upper === 'CREDIT' || upper === 'DEPOSIT') {
                    whereClauses.push(`wt.type IN ('CREDIT', 'DEPOSIT', 'REFUND', 'RELEASE')`);
                } else if (upper === 'DEBIT' || upper === 'ORDER') {
                    whereClauses.push(`wt.type IN ('DEBIT', 'ORDER', 'HOLD', 'RESERVE')`);
                } else if (upper === 'PAYOUT') {
                    whereClauses.push(`(wt.type = 'PAYOUT' OR wt.reference_type = 'WITHDRAWAL')`);
                } else {
                    whereClauses.push(`wt.type = ?`);
                    params.push(upper);
                }
            }

            if (search && search.trim().length > 0) {
                const term = `%${search.trim().toLowerCase()}%`;
                whereClauses.push(`(LOWER(wt.description) LIKE ? OR LOWER(u.email) LIKE ? OR LOWER(u.full_name) LIKE ? OR wt.id LIKE ?)`);
                params.push(term, term, term, term);
            }

            const whereSql = whereClauses.length > 0 ? `WHERE ${whereClauses.join(' AND ')}` : '';

            const querySql = `
                SELECT 
                    wt.id,
                    wt.type,
                    CAST(wt.amount AS DECIMAL(12,2)) as amount,
                    CAST(wt.balance_after AS DECIMAL(12,2)) as balanceAfter,
                    wt.description,
                    wt.status,
                    wt.created_at as createdAt,
                    wt.reference_id as referenceId,
                    wt.reference_type as referenceType,
                    u.id as userId,
                    u.full_name as userName,
                    u.email as userEmail,
                    u.role as userRole
                FROM wallet_transactions wt
                LEFT JOIN wallets w ON wt.wallet_id = w.id
                LEFT JOIN users u ON w.user_id = u.id
                ${whereSql}
                ORDER BY wt.created_at DESC
                LIMIT ? OFFSET ?
            `;

            const countSql = `
                SELECT COUNT(*) as total
                FROM wallet_transactions wt
                LEFT JOIN wallets w ON wt.wallet_id = w.id
                LEFT JOIN users u ON w.user_id = u.id
                ${whereSql}
            `;

            const [items, [countRow]] = await Promise.all([
                this.dataSource.query(querySql, [...params, safeLimit, offset]),
                this.dataSource.query(countSql, params),
            ]);

            return {
                success: true,
                total: parseInt(countRow?.total || 0, 10),
                page: safePage,
                limit: safeLimit,
                ledger: items.map((item: any) => ({
                    id: item.id,
                    type: item.type,
                    amount: parseFloat(item.amount || 0),
                    balanceAfter: parseFloat(item.balanceAfter || 0),
                    title: item.description || (item.type === 'CREDIT' ? 'Wallet Deposit / Credit' : 'Campaign Order Payment'),
                    description: item.description || '',
                    status: item.status || 'COMPLETED',
                    createdAt: item.createdAt,
                    date: item.createdAt,
                    userName: item.userName || (item.userEmail ? item.userEmail.split('@')[0] : 'Platform User'),
                    userEmail: item.userEmail || '',
                    userRole: item.userRole || '',
                    referenceId: item.referenceId || item.id,
                })),
            };
        } catch (error: any) {
            return {
                success: false,
                error: error?.message || 'Failed to fetch ledger stream',
                total: 0,
                page: 1,
                limit: 50,
                ledger: [],
            };
        }
    }
}
