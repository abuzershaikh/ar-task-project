import { Injectable, Logger, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { TaskRepository } from '../../../database/repositories/task.repository';
import { OrderRepository } from '../../../database/repositories/order.repository';
import { SystemSettingsRepository } from '../../../database/repositories/system-settings.repository';
import { TaskReleaseService } from './task-release.service';
import { ReassignmentService } from './reassignment.service';
import { ReleaseReason, PostDeadlineEvaluation } from '../types/reallocation.types';

@Injectable()
export class DeadlineMonitorService implements OnModuleInit, OnModuleDestroy {
    private readonly logger = new Logger(DeadlineMonitorService.name);
    private monitorInterval: NodeJS.Timeout | null = null;
    private isRunningCycle = false;

    constructor(
        private readonly taskRepo: TaskRepository,
        private readonly orderRepo: OrderRepository,
        private readonly settingsRepo: SystemSettingsRepository,
        private readonly releaseService: TaskReleaseService,
        private readonly reassignmentService: ReassignmentService,
    ) { }

    onModuleInit() {
        this.logger.log('🕒 Initializing automated real-time Task Deadline & Expiry Monitor background service (interval: 60s)...');
        // Initial delayed check (15s after startup)
        setTimeout(() => {
            this.monitorDeadlines().catch((err) =>
                this.logger.warn(`Initial deadline monitor execution warning: ${err.message}`),
            );
        }, 15000);

        // Continuous 60-second recurring background interval
        this.monitorInterval = setInterval(async () => {
            if (this.isRunningCycle) return;
            try {
                this.isRunningCycle = true;
                await this.monitorDeadlines();
            } catch (err) {
                this.logger.error(`Automated deadline monitor cycle error: ${err.message}`);
            } finally {
                this.isRunningCycle = false;
            }
        }, 60000);
    }

    onModuleDestroy() {
        if (this.monitorInterval) {
            clearInterval(this.monitorInterval);
            this.monitorInterval = null;
        }
    }

    /**
     * Retrieves dynamic system settings for task expiration
     */
    async getExpirySettings() {
        try {
            const workerTimeout = await this.settingsRepo.findByKey('worker_execution_timeout_hours');
            const unacceptedExpiry = await this.settingsRepo.findByKey('unaccepted_task_expiry_hours');
            const autoReassign = await this.settingsRepo.findByKey('auto_reassign_on_expiry');

            return {
                workerExecutionTimeoutHours: workerTimeout ? Number(workerTimeout.value) : 2.0,
                unacceptedTaskExpiryHours: unacceptedExpiry ? Number(unacceptedExpiry.value) : 24.0,
                autoReassignOnExpiry: autoReassign !== null && autoReassign !== undefined ? Boolean(autoReassign.value) : true,
            };
        } catch (_) {
            return {
                workerExecutionTimeoutHours: 2.0,
                unacceptedTaskExpiryHours: 24.0,
                autoReassignOnExpiry: true,
            };
        }
    }

    /**
     * Executes the Post-Deadline Monitor cycle.
     * Evaluates:
     * 1. Worker Full Timeouts: Releases expired workers who accepted but did not submit proof.
     * 2. Campaign Auto-Extensions & Unaccepted task management.
     */
    async monitorDeadlines(campaignAutoExtensionHours: number = 10): Promise<PostDeadlineEvaluation> {
        this.logger.log('Starting Post-Deadline Monitor cycle...');
        const settings = await this.getExpirySettings();

        // 1. Process Worker Acceptance Timeouts (Independent of campaign expiry)
        const timeoutResults = await this.processFullTimeouts(settings.workerExecutionTimeoutHours, settings.autoReassignOnExpiry);

        // 2. Process Campaign Auto-Extensions (+10 hours if campaign incomplete at expiry date)
        const extensionResults = await this.processCampaignAutoExtensions(campaignAutoExtensionHours);

        return {
            evaluatedTasksCount: timeoutResults.evaluatedCount,
            expiredTasksCount: timeoutResults.expiredCount,
            reallocatedTasksCount: timeoutResults.reallocatedCount,
            extendedCampaignsCount: extensionResults.extendedCampaignsCount,
        };
    }

    async processFullTimeouts(
        defaultWorkerTimeoutHours: number = 2.0,
        autoReassign: boolean = true,
    ): Promise<{ evaluatedCount: number; expiredCount: number; reallocatedCount: number }> {
        const now = new Date();
        const activeAssignedTasks = await this.taskRepo.findAssignedTasks();

        let evaluatedCount = 0;
        let expiredCount = 0;
        let reallocatedCount = 0;

        for (const task of activeAssignedTasks) {
            const campaignId = task.campaignId || task.orderId;
            const assignedWorkerId = task.assignedTo;

            if (!assignedWorkerId) continue;

            evaluatedCount++;

            // Production Protection: ONLY process ASSIGNED, ACCEPTED, or IN_PROGRESS tasks.
            // SUBMITTED, UNDER_REVIEW, APPROVED, and COMPLETED tasks are STRICTLY UNTOUCHABLE.
            const allowedStatuses = ['ASSIGNED', 'assigned', 'ACCEPTED', 'accepted', 'IN_PROGRESS', 'in_progress'];
            if (!allowedStatuses.includes(task.status)) {
                continue;
            }

            // Determine deadline
            let effectiveDeadline: Date | null = task.deadline ? new Date(task.deadline) : null;
            if (!effectiveDeadline || isNaN(effectiveDeadline.getTime())) {
                const acceptTime = task.acceptedAt || task.assignedAt || task.startedAt;
                if (acceptTime) {
                    effectiveDeadline = new Date(new Date(acceptTime).getTime() + defaultWorkerTimeoutHours * 3600 * 1000);
                }
            }

            // Check if deadline passed
            if (effectiveDeadline && effectiveDeadline < now) {
                this.logger.warn(`POST-DEADLINE TIMEOUT: Task '${task.id}' deadline (${effectiveDeadline.toISOString()}) passed for Worker '${assignedWorkerId}'.`);

                // 1. Release worker with reason WORKER_TIMEOUT (Locks participation in DB -> Worker excluded from this task)
                const released = await this.releaseService.releaseWorkerFromTask({
                    taskId: task.id,
                    workerId: assignedWorkerId,
                    campaignId,
                    reason: ReleaseReason.WORKER_TIMEOUT,
                    details: 'Task completion deadline expired without proof submission',
                });

                if (released) {
                    expiredCount++;

                    // 2. If autoReassign is enabled, immediately reassign or release to pool for other workers
                    if (autoReassign) {
                        const newWorkerId = await this.reassignmentService.reassignTaskToNewWorker(task.id, campaignId);
                        if (newWorkerId) {
                            reallocatedCount++;
                            this.logger.log(`✅ Auto-reassigned expired task '${task.id}' to new worker '${newWorkerId}'`);
                        } else {
                            this.logger.log(`📢 Task '${task.id}' released back to active pool for any eligible worker to accept.`);
                        }
                    }
                }
            }
        }

        return { evaluatedCount, expiredCount, reallocatedCount };
    }

    async processCampaignAutoExtensions(extensionHours: number = 10): Promise<{ extendedCampaignsCount: number }> {
        const now = new Date();
        let extendedCampaignsCount = 0;

        const activeOrders = await this.orderRepo.findActiveOrders();
        for (const order of activeOrders) {
            const currentExpiry = order.campaignExpiryDate;
            
            if (currentExpiry && new Date(currentExpiry) < now && order.tasksCompleted < order.totalTasksRequired) {
                const newExpiryDate = new Date(new Date(currentExpiry).getTime() + extensionHours * 3600 * 1000);
                
                const extensionHistory = order.extensionHistory || [];
                extensionHistory.push({
                    extendedAt: now.toISOString(),
                    previousExpiry: currentExpiry.toISOString(),
                    newExpiry: newExpiryDate.toISOString(),
                    extensionHours,
                });

                await this.orderRepo.update(order.id, {
                    campaignExpiryDate: newExpiryDate,
                    extensionCount: (order.extensionCount || 0) + 1,
                    extensionHistory,
                });
                
                extendedCampaignsCount++;
                this.logger.log(
                    `CAMPAIGN_AUTO_EXTENDED_NEW_ALLOCATION_WINDOW_OPEN: Order '${order.id}' extended by +${extensionHours} hours to ${newExpiryDate.toISOString()} for remaining ${order.totalTasksRequired - order.tasksCompleted} tasks. Candidate recruitment reopened.`,
                );
            }
        }

        return { extendedCampaignsCount };
    }
}
