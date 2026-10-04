import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { UserRepository } from '../../../../shared/database/repositories/user.repository';
import { WorkerRepository } from '../../../../shared/database/repositories/worker.repository';
import { OrderRepository } from '../../../../shared/database/repositories/order.repository';
import { TaskRepository } from '../../../../shared/database/repositories/task.repository';
import { SubmissionRepository } from '../../../../shared/database/repositories/submission.repository';
import { KycRepository } from '../../../../shared/database/repositories/kyc.repository';
import { WithdrawalRepository } from '../../../../shared/database/repositories/withdrawal.repository';
import { EarningRepository } from '../../../../shared/database/repositories/earning.repository';
import { Roles } from '../../../../shared/auth/decorators/roles.decorator';
import { UserRole } from '../../../../shared/database/entities/user.entity';
import { Worker } from '../../../../shared/database/entities/worker.entity';
import { DataSource } from 'typeorm';

@ApiTags('Admin - Master Dashboard')
@Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
@ApiBearerAuth('bearer')
@Controller('admin/dashboard')
export class AdminDashboardController {
    constructor(
        private readonly userRepo: UserRepository,
        private readonly workerRepo: WorkerRepository,
        private readonly orderRepo: OrderRepository,
        private readonly taskRepo: TaskRepository,
        private readonly submissionRepo: SubmissionRepository,
        private readonly kycRepo: KycRepository,
        private readonly withdrawalRepo: WithdrawalRepository,
        private readonly earningRepo: EarningRepository,
        private readonly dataSource: DataSource,
    ) { }

    @Get()
    @ApiOperation({ summary: 'Master Admin Dashboard single-call high-level metrics' })
    async getMasterDashboard() {
        const workers = await this.userRepo.findByRole(UserRole.WORKER);
        const buyers = await this.userRepo.findByRole(UserRole.BUYER);
        const workerEntities = await this.dataSource.getRepository(Worker).find();
        const pendingKyc = await this.kycRepo.findPending();
        const pendingReviews = await this.submissionRepo.findPendingReviews();
        const pendingPayouts = await this.withdrawalRepo.findPending();

        const workerMap = new Map<string, any>();
        for (const w of workerEntities) {
            workerMap.set(w.userId, w);
        }

        const cutoff48h = Date.now() - 48 * 60 * 60 * 1000;

        let activeWorkers = 0;
        let inactiveWorkers = 0;
        for (const u of workers) {
            const w = workerMap.get(u.id);
            const lastActive = w?.lastActiveAt || u.lastLogin || (u as any).last_login;
            const isRecentlyActive = lastActive && new Date(lastActive).getTime() > cutoff48h;
            const isAcctActive = (u.status || 'ACTIVE').toUpperCase() === 'ACTIVE';

            if (isAcctActive && isRecentlyActive) {
                activeWorkers++;
            } else {
                inactiveWorkers++;
            }
        }

        let activeBuyers = 0;
        let inactiveBuyers = 0;
        for (const b of buyers) {
            const lastActive = b.lastLogin || (b as any).last_login;
            const isRecentlyActive = lastActive && new Date(lastActive).getTime() > cutoff48h;
            const isAcctActive = (b.status || 'ACTIVE').toUpperCase() === 'ACTIVE';

            if (isAcctActive && isRecentlyActive) {
                activeBuyers++;
            } else {
                inactiveBuyers++;
            }
        }

        return {
            success: true,
            dashboard: {
                users: {
                    totalBuyers: buyers.length,
                    activeBuyers,
                    inactiveBuyers,
                    totalWorkers: workers.length,
                    activeWorkers,
                    inactiveWorkers,
                    totalUsers: workers.length + buyers.length,
                    activeUsers: activeWorkers + activeBuyers,
                    inactiveUsers: inactiveWorkers + inactiveBuyers,
                },
                queues: {
                    pendingKycCount: pendingKyc.length,
                    pendingReviewCount: pendingReviews.length,
                    pendingPayoutsCount: pendingPayouts.length,
                },
            },
        };
    }

    @Get('orders')
    @ApiOperation({ summary: 'Admin Dashboard - Orders breakdown metrics' })
    async getOrdersDashboard() {
        const total = await this.orderRepo.count();
        const pending = await this.orderRepo.count({ where: { status: 'PENDING' } });
        const active = await this.orderRepo.count({ where: { status: 'ACTIVE' } });
        const completed = await this.orderRepo.count({ where: { status: 'COMPLETED' } });
        const cancelled = await this.orderRepo.count({ where: { status: 'CANCELLED' } });

        return {
            success: true,
            ordersSummary: {
                totalOrders: total,
                pendingOrders: pending,
                activeOrders: active,
                completedOrders: completed,
                cancelledOrders: cancelled,
            },
        };
    }

    @Get('tasks')
    @ApiOperation({ summary: 'Admin Dashboard - Tasks status breakdown across platform' })
    async getTasksDashboard() {
        const total = await this.taskRepo.count();
        const pending = await this.taskRepo.count({ where: { status: 'PENDING' } });
        const assigned = await this.taskRepo.count({ where: { status: 'ASSIGNED' } });
        const inProgress = await this.taskRepo.count({ where: { status: 'IN_PROGRESS' } });
        const submitted = await this.taskRepo.count({ where: { status: 'SUBMITTED' } });
        const approved = await this.taskRepo.count({ where: { status: 'APPROVED' } });
        const rejected = await this.taskRepo.count({ where: { status: 'REJECTED' } });
        const completed = await this.taskRepo.count({ where: { status: 'COMPLETED' } });

        return {
            success: true,
            tasksSummary: {
                totalTasks: total,
                pending,
                assigned,
                inProgress,
                submitted,
                approved,
                rejected,
                completed,
            },
        };
    }

    @Get('workers')
    @ApiOperation({ summary: 'Admin Dashboard - Worker tier and status metrics' })
    async getWorkersDashboard() {
        const workers = await this.userRepo.findByRole(UserRole.WORKER);
        const workerEntities = await this.dataSource.getRepository(Worker).find();
        const cutoff48h = Date.now() - 48 * 60 * 60 * 1000;

        const workerMap = new Map<string, any>();
        for (const w of workerEntities) {
            workerMap.set(w.userId, w);
        }

        let activeCount = 0;
        let inactiveCount = 0;
        let kycVerifiedCount = 0;

        for (const u of workers) {
            const w = workerMap.get(u.id);
            const lastActive = w?.lastActiveAt || u.lastLogin || (u as any).last_login;
            const isRecentlyActive = lastActive && new Date(lastActive).getTime() > cutoff48h;
            const isAcctActive = (u.status || 'ACTIVE').toUpperCase() === 'ACTIVE';

            if (isAcctActive && isRecentlyActive) {
                activeCount++;
            } else {
                inactiveCount++;
            }

            const kyc = (w?.kycStatus || '').toLowerCase();
            if (kyc === 'approved' || kyc === 'verified') {
                kycVerifiedCount++;
            }
        }

        return {
            success: true,
            workersSummary: {
                totalWorkers: workers.length,
                activeCount,
                inactiveCount,
                kycVerifiedCount,
            },
        };
    }

    @Get('buyers')
    @ApiOperation({ summary: 'Admin Dashboard - Buyer activity and spend metrics' })
    async getBuyersDashboard() {
        const buyers = await this.userRepo.findByRole(UserRole.BUYER);
        const cutoff48h = Date.now() - 48 * 60 * 60 * 1000;

        let activeCount = 0;
        let inactiveCount = 0;
        for (const b of buyers) {
            const lastActive = b.lastLogin || (b as any).last_login;
            const isRecentlyActive = lastActive && new Date(lastActive).getTime() > cutoff48h;
            const isAcctActive = (b.status || 'ACTIVE').toUpperCase() === 'ACTIVE';

            if (isAcctActive && isRecentlyActive) {
                activeCount++;
            } else {
                inactiveCount++;
            }
        }

        return {
            success: true,
            buyersSummary: {
                totalBuyers: buyers.length,
                activeCount,
                inactiveCount,
            },
        };
    }

    @Get('earnings')
    @ApiOperation({ summary: 'Admin Dashboard - Gross platform revenue and worker earnings' })
    async getEarningsDashboard() {
        const totalEarnings = await this.earningRepo.sumTotalEarnings();
        const totalPayouts = await this.withdrawalRepo.sumPaidWithdrawals();
        const metrics = await this.orderRepo.getPlatformFinancialMetrics();

        return {
            success: true,
            financialSummary: {
                grossPlatformVolume: metrics.grossVolume || totalEarnings,
                workerPayoutsDisbursed: totalPayouts || 0.0,
                platformNetMargin: metrics.platformMargin || 0.0,
            },
        };
    }

    @Get('payouts')
    @ApiOperation({ summary: 'Admin Dashboard - Payout metrics' })
    async getPayoutsDashboard() {
        const pendingPayouts = await this.withdrawalRepo.findPending();
        return {
            success: true,
            payoutsSummary: {
                pendingPayoutsCount: pendingPayouts.length,
            },
        };
    }
}
