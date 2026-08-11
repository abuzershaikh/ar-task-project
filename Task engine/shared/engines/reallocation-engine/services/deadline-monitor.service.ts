import { Injectable, Logger } from '@nestjs/common';
import { TaskRepository } from '../../../database/repositories/task.repository';
import { OrderRepository } from '../../../database/repositories/order.repository';
import { TaskReleaseService } from './task-release.service';
import { ReassignmentService } from './reassignment.service';
import { ReleaseReason, PostDeadlineEvaluation } from '../types/reallocation.types';

@Injectable()
export class DeadlineMonitorService {
    private readonly logger = new Logger(DeadlineMonitorService.name);

    constructor(
        private readonly taskRepo: TaskRepository,
        private readonly orderRepo: OrderRepository,
        private readonly releaseService: TaskReleaseService,
        private readonly reassignmentService: ReassignmentService,
    ) { }

    /**
     * Executes the Post-Deadline Monitor cycle.
     * Production Rules:
     * 1. Task timeout processing is COMPLETELY INDEPENDENT of campaign expiry date.
     *    Worker W03 timing out at 10 PM triggers WORKER_TIMEOUT, release, and W11 reassignment immediately.
     * 2. processFullTimeouts MUST process ONLY ASSIGNED, ACCEPTED, or IN_PROGRESS tasks.
     *    SUBMITTED, UNDER_REVIEW, APPROVED, COMPLETED tasks are STRICTLY UNTOUCHABLE.
     * 3. campaign_worker_participation records are NEVER deleted or reused. Record existence = permanent exclusion from campaign.
     * 4. When campaign expiry cutoff arrives with incomplete tasks, campaign auto-extends (+10 hours) and opens new allocation window.
     */
    async monitorDeadlines(campaignAutoExtensionHours: number = 10): Promise<PostDeadlineEvaluation> {
        this.logger.log('Starting Post-Deadline Monitor cycle...');

        // 1. Process Full Timeouts (Independent of campaign expiry)
        const timeoutResults = await this.processFullTimeouts();

        // 2. Process Campaign Auto-Extensions (+10 hours if campaign incomplete at expiry date)
        const extensionResults = await this.processCampaignAutoExtensions(campaignAutoExtensionHours);

        return {
            evaluatedTasksCount: timeoutResults.evaluatedCount,
            expiredTasksCount: timeoutResults.expiredCount,
            reallocatedTasksCount: timeoutResults.reallocatedCount,
            extendedCampaignsCount: extensionResults.extendedCampaignsCount,
        };
    }

    async processFullTimeouts(): Promise<{ evaluatedCount: number; expiredCount: number; reallocatedCount: number }> {
        const now = new Date();
        const activeAssignedTasks = await this.taskRepo.findAssignedTasks();

        let evaluatedCount = 0;
        let expiredCount = 0;
        let reallocatedCount = 0;

        for (const task of activeAssignedTasks) {
            const campaignId = task.campaignId || task.orderId;
            const assignedWorkerId = task.assignedTo;

            if (!assignedWorkerId || !task.deadline) continue;

            evaluatedCount++;

            // Production Protection: ONLY process ASSIGNED, ACCEPTED, or IN_PROGRESS tasks.
            // SUBMITTED, UNDER_REVIEW, APPROVED, and COMPLETED tasks are STRICTLY UNTOUCHABLE.
            const allowedStatuses = ['ASSIGNED', 'assigned', 'ACCEPTED', 'accepted', 'IN_PROGRESS', 'in_progress'];
            if (!allowedStatuses.includes(task.status)) {
                continue;
            }

            // Worker gets full task deadline! Worker timeout triggers immediately at task.deadline (independent of campaign expiry)
            if (new Date(task.deadline) < now) {
                this.logger.warn(`POST-DEADLINE TIMEOUT: Task '${task.id}' deadline passed for Worker '${assignedWorkerId}'.`);

                // 1. Release worker with reason WORKER_TIMEOUT (Locks participation in DB -> Worker permanently excluded from Campaign)
                const released = await this.releaseService.releaseWorkerFromTask({
                    taskId: task.id,
                    workerId: assignedWorkerId,
                    campaignId,
                    reason: ReleaseReason.WORKER_TIMEOUT,
                    details: 'Task completion deadline expired without proof submission',
                });

                if (released) {
                    expiredCount++;

                    // 2. Reassign task immediately to a NEW unused worker in the campaign (independent of campaign expiry)
                    const newWorkerId = await this.reassignmentService.reassignTaskToNewWorker(task.id, campaignId);
                    if (newWorkerId) {
                        reallocatedCount++;
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
            const expiryDate = order.campaignExpiryDateSnapshot || order.campaignExpiryDate;
            if (expiryDate && new Date(expiryDate) < now && order.tasksCompleted < order.totalTasksRequired) {
                const newExpiryDate = new Date(now.getTime() + extensionHours * 3600 * 1000);
                await this.orderRepo.update(order.id, {
                    campaignExpiryDate: newExpiryDate,
                    campaignExpiryDateSnapshot: newExpiryDate,
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
