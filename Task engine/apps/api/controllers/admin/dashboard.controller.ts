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
    ) { }

    @Get()
    @ApiOperation({ summary: 'Master Admin Dashboard single-call high-level metrics' })
    async getMasterDashboard() {
        const workers = await this.workerRepo.findActiveWorkers();
        const buyers = await this.userRepo.findByRole(UserRole.BUYER);
        const pendingKyc = await this.kycRepo.findPending();
        const pendingReviews = await this.submissionRepo.findPendingReviews();
        const pendingPayouts = await this.withdrawalRepo.findPending();

        return {
            success: true,
            dashboard: {
                users: {
                    totalBuyers: buyers.length,
                    activeBuyers: buyers.filter((b) => b.status === 'ACTIVE').length,
                    totalWorkers: workers.length,
                    activeWorkers: workers.filter((w) => w.status === 'active').length,
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
        const workers = await this.workerRepo.findActiveWorkers();
        return {
            success: true,
            workersSummary: {
                totalWorkers: workers.length,
                activeCount: workers.filter((w) => w.status === 'active').length,
                kycVerifiedCount: workers.filter((w) => w.kycStatus === 'verified').length,
            },
        };
    }

    @Get('buyers')
    @ApiOperation({ summary: 'Admin Dashboard - Buyer activity and spend metrics' })
    async getBuyersDashboard() {
        const buyers = await this.userRepo.findByRole(UserRole.BUYER);
        return {
            success: true,
            buyersSummary: {
                totalBuyers: buyers.length,
                activeCount: buyers.filter((b) => b.status === 'ACTIVE').length,
            },
        };
    }

    @Get('earnings')
    @ApiOperation({ summary: 'Admin Dashboard - Gross platform revenue and worker earnings' })
    async getEarningsDashboard() {
        const totalEarnings = await this.earningRepo.sumTotalEarnings();
        const totalPayouts = await this.withdrawalRepo.sumPaidWithdrawals();

        return {
            success: true,
            financialSummary: {
                grossPlatformVolume: totalEarnings + (totalEarnings * 0.3),
                workerPayoutsDisbursed: totalPayouts || 0.0,
                platformNetMargin: totalEarnings * 0.3,
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
