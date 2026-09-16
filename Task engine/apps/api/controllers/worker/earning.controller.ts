import {
    Controller,
    Get,
    Post,
    Body,
    Req,
    BadRequestException,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { KycStatus } from '../../../../shared/database/entities/kyc.entity';
import { EarningRepository } from '../../../../shared/database/repositories/earning.repository';
import { WithdrawalRepository } from '../../../../shared/database/repositories/withdrawal.repository';
import { WorkerRepository } from '../../../../shared/database/repositories/worker.repository';
import { WalletRepository } from '../../../../shared/database/repositories/wallet.repository';
import { TaskRepository } from '../../../../shared/database/repositories/task.repository';
import { WalletTransactionRepository } from '../../../../shared/database/repositories/wallet-transaction.repository';
import { WithdrawalStatus } from '../../../../shared/database/entities/withdrawal.entity';
import { PayoutEngineService } from '../../../../payout-engine/payout.service';
import { CurrentUser } from '../../../../shared/auth/decorators/current-user.decorator';
import { Roles } from '../../../../shared/auth/decorators/roles.decorator';
import { UserRole, User } from '../../../../shared/database/entities/user.entity';

function formatTaskType(type: string): string {
    if (!type) return 'Task';
    return type
        .replace(/_/g, ' ')
        .toLowerCase()
        .replace(/\b\w/g, (c) => c.toUpperCase());
}

@ApiTags('Worker - Earnings & Wallet')
@Roles(UserRole.WORKER)
@ApiBearerAuth('bearer')
@Controller('worker/earnings')
export class WorkerEarningController {
    constructor(
        private readonly earningRepo: EarningRepository,
        private readonly withdrawalRepo: WithdrawalRepository,
        private readonly workerRepo: WorkerRepository,
        private readonly walletRepo: WalletRepository,
        private readonly taskRepo: TaskRepository,
        private readonly walletTxRepo: WalletTransactionRepository,
        private readonly payoutEngine: PayoutEngineService,
    ) { }

    @Get()
    @ApiOperation({ summary: 'Get worker earnings & unified transaction history' })
    async getEarnings(@CurrentUser() user: User) {
        const worker = await this.workerRepo.findByUserId(user.id);
        const workerIds = Array.from(new Set([user.id, worker?.id].filter(Boolean) as string[]));

        // 1. Fetch raw earnings
        const earnings = await this.earningRepo.findByWorker(workerIds);

        // Fetch task details for richer labels
        const taskIds = Array.from(new Set(earnings.map((e) => e.taskId).filter(Boolean)));
        let taskMap = new Map<string, any>();
        if (taskIds.length > 0) {
            try {
                const tasks = await this.taskRepo.findByIds(taskIds);
                taskMap = new Map(tasks.map((t) => [t.id, t]));
            } catch (err) {
                // Non-fatal, fallback to metadata
            }
        }

        // 2. Fetch withdrawals
        const withdrawals = await this.withdrawalRepo.findByWorker(workerIds);
        const knownWithdrawalIds = new Set<string>();
        for (const w of withdrawals) {
            knownWithdrawalIds.add(w.id);
            if (w.transactionId) knownWithdrawalIds.add(w.transactionId);
        }

        // 3. Fetch wallet transactions for user wallet (deductions / adjustments)
        let walletDebits: any[] = [];
        try {
            const wallet = await this.walletRepo.findByUserId(user.id);
            if (wallet) {
                const res = await this.walletTxRepo.findByWallet(wallet.id, 'DEBIT', 1, 100);
                walletDebits = res.transactions || [];
            }
        } catch (err) {
            // Non-fatal
        }

        const unified: any[] = [];

        // Map earnings
        for (const e of earnings) {
            const task = taskMap.get(e.taskId);
            const appName = task?.metadata?.appName || task?.requirements?.appName || e.metadata?.appName;
            const serviceName = task?.requirements?.serviceName || e.metadata?.serviceName;
            const taskType = e.metadata?.taskType || task?.taskType || 'TASK_EARNING';

            let title = 'Task Earning';
            if (appName && serviceName) {
                title = `${appName} - ${serviceName}`;
            } else if (appName) {
                title = `${appName} - ${formatTaskType(taskType)}`;
            } else if (serviceName) {
                title = serviceName;
            } else {
                title = `${formatTaskType(taskType)} Earning`;
            }

            unified.push({
                id: e.id,
                type: 'EARNING',
                title,
                description: `Completed task #${e.taskId ? e.taskId.substring(0, 8) : 'reward'}`,
                amount: Number(e.amount || 0),
                status: e.status === 'posted' ? 'COMPLETED' : (e.status || 'COMPLETED').toUpperCase(),
                date: e.createdAt,
                createdAt: e.createdAt,
                referenceId: e.taskId || e.id,
                metadata: {
                    taskId: e.taskId,
                    appName,
                    appIcon: task?.metadata?.appIcon || task?.requirements?.appIcon || e.metadata?.appIcon,
                    taskType,
                },
            });
        }

        // Map withdrawals
        for (const w of withdrawals) {
            unified.push({
                id: w.id,
                type: 'WITHDRAWAL',
                title: w.paymentMethodId ? `Payout via ${w.paymentMethodId}` : 'Withdrawal Request',
                description: w.transactionId
                    ? `Ref: ${w.transactionId}`
                    : (w.status === WithdrawalStatus.PAID ? 'Payout Completed' : 'Under Review / Processing'),
                amount: Number(w.amount || 0),
                status: (w.status || 'REQUESTED').toUpperCase(),
                date: w.createdAt,
                createdAt: w.createdAt,
                referenceId: w.transactionId || w.id,
                metadata: {
                    paymentMethodId: w.paymentMethodId,
                    transactionId: w.transactionId,
                    rejectionReason: w.rejectionReason,
                },
            });
        }

        // Map deductions (only worker penalties/adjustments; ignore buyer campaign orders)
        for (const wt of walletDebits) {
            const refId = wt.referenceId;
            if (refId && knownWithdrawalIds.has(refId)) {
                continue; // already in withdrawals
            }
            const desc = (wt.description || '').toLowerCase();
            if (desc.includes('withdrawal')) {
                continue;
            }
            // Exclude buyer campaign orders - workers should not see buyer orders
            if (desc.startsWith('campaign order') || desc.includes('campaign') || desc.startsWith('order:')) {
                continue;
            }

            unified.push({
                id: wt.id,
                type: 'DEDUCTION',
                title: wt.description || 'Wallet Deduction',
                description: wt.referenceType ? `${wt.referenceType} debit` : 'Account balance deduction',
                amount: Number(wt.amount || 0),
                status: (wt.status || 'COMPLETED').toUpperCase(),
                date: wt.createdAt,
                createdAt: wt.createdAt,
                referenceId: wt.referenceId || wt.id,
            });
        }

        // Sort by createdAt descending
        unified.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());

        return {
            success: true,
            transactions: unified,
            earnings,
            withdrawals,
        };
    }

    @Get('wallet')
    @ApiOperation({ summary: 'Get worker wallet summary with minimum withdrawal threshold' })
    async getWallet(@CurrentUser() user: User) {
        const worker = await this.workerRepo.findByUserId(user.id);
        const workerIds = Array.from(new Set([user.id, worker?.id].filter(Boolean) as string[]));
        const minWithdrawalLimit = worker?.profile?.minWithdrawalLimit || this.payoutEngine.getMinWithdrawalLimit();

        const totalEarned = await this.earningRepo.getTotalEarnings(workerIds);

        const totalDeducted = await this.withdrawalRepo.getTotalWithdrawalsAmount(workerIds, [
            WithdrawalStatus.REQUESTED,
            WithdrawalStatus.UNDER_REVIEW,
            WithdrawalStatus.PROCESSING,
            WithdrawalStatus.PAID,
        ]);

        const pendingWithdrawals = await this.withdrawalRepo.getTotalWithdrawalsAmount(workerIds, [
            WithdrawalStatus.REQUESTED,
            WithdrawalStatus.UNDER_REVIEW,
            WithdrawalStatus.PROCESSING,
        ]);

        const availableBalance = Math.max(0, totalEarned - totalDeducted);
        const isEligibleToWithdraw = availableBalance >= minWithdrawalLimit;

        const earnings = await this.earningRepo.findByWorker(workerIds);
        const withdrawals = await this.withdrawalRepo.findByWorker(workerIds);

        // Fetch wallet table record for user
        const wallet = await this.walletRepo.findByUserId(user.id);

        return {
            success: true,
            worker,
            wallet: {
                totalEarned,
                totalDeducted,
                pendingWithdrawals,
                availableBalance,
                reservedBalance: wallet ? Number(wallet.reservedBalance || 0) : pendingWithdrawals,
                minWithdrawalLimit,
                isEligibleToWithdraw,
                earningsCount: earnings.length,
                withdrawalsCount: withdrawals.length,
            },
        };
    }

    @Get('balance')
    @ApiOperation({ summary: 'Get worker available balance' })
    async getBalance(@CurrentUser() user: User) {
        const walletRes = await this.getWallet(user);
        return {
            availableBalance: walletRes.wallet.availableBalance,
            totalEarned: walletRes.wallet.totalEarned,
            totalDeducted: walletRes.wallet.totalDeducted,
            pendingWithdrawals: walletRes.wallet.pendingWithdrawals,
            minWithdrawalLimit: walletRes.wallet.minWithdrawalLimit,
            isEligibleToWithdraw: walletRes.wallet.isEligibleToWithdraw,
        };
    }

    @Post('withdraw')
    @ApiOperation({ summary: 'Request withdrawal (Enforces minimum limit and idempotency)' })
    async requestWithdrawal(
        @CurrentUser() user: User,
        @Req() req: any,
        @Body()
        body: {
            amount: number;
            paymentMethodId?: string;
            paymentMethod?: string;
            idempotencyKey?: string;
            metadata?: any;
        },
    ) {
        if (!body.amount || body.amount <= 0) {
            throw new BadRequestException('Withdrawal amount must be greater than 0');
        }

        const walletRes = await this.getWallet(user);
        const minLimit = walletRes.wallet.minWithdrawalLimit;

        const isKycValid = walletRes.worker?.kycStatus === KycStatus.VERIFIED || 
                           walletRes.worker?.kycStatus === KycStatus.SUBMITTED;
        if (!isKycValid) {
            throw new BadRequestException('Please add and submit your bank or payout details before requesting a withdrawal');
        }

        if (body.amount < minLimit) {
            throw new BadRequestException(
                `Minimum withdrawal threshold is ₹${minLimit.toFixed(2)}. Your requested amount of ₹${body.amount.toFixed(2)} does not meet the minimum requirement.`,
            );
        }

        if (body.amount > walletRes.wallet.availableBalance) {
            throw new BadRequestException(
                `Insufficient balance. Available: ₹${walletRes.wallet.availableBalance.toFixed(2)}, Requested: ₹${body.amount.toFixed(2)}`,
            );
        }

        const effectiveIdempotencyKey = body.idempotencyKey || req?.headers?.['idempotency-key'] as string;

        const withdrawalId = await this.payoutEngine.initiateWithdrawal({
            workerId: user.id,
            amount: body.amount,
            paymentMethod: body.paymentMethodId || body.paymentMethod || 'DEFAULT',
            idempotencyKey: effectiveIdempotencyKey,
            metadata: body.metadata,
        });

        return {
            success: true,
            withdrawalId,
            status: WithdrawalStatus.REQUESTED,
            message: 'Withdrawal request submitted successfully and is pending review',
        };
    }

    @Get('withdrawals')
    @ApiOperation({ summary: 'Get worker withdrawal history' })
    async getWithdrawals(@CurrentUser() user: User) {
        const worker = await this.workerRepo.findByUserId(user.id);
        const workerIds = Array.from(new Set([user.id, worker?.id].filter(Boolean) as string[]));
        const withdrawals = await this.withdrawalRepo.findByWorker(workerIds);
        return {
            success: true,
            withdrawals,
        };
    }
}
