import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { TaskEngineService } from '../../task-engine/task-engine.service';
import { OrderRepository } from '../database/repositories/order.repository';
import { TaskRepository } from '../database/repositories/task.repository';
import { TaskGenerationJobRepository } from '../database/repositories/task-generation-job.repository';
import { TaskGenerationJobStatus } from '../database/entities/task-generation-job.entity';

export interface OrderActivatedEventPayload {
    orderId: string;
    jobId?: string;
    buyerId: string;
    serviceCode: string;
    totalTasksRequired: number;
    workerRewardSnapshot: number;
    paymentTransactionId?: string;
    activatedAt: Date;
}

@Injectable()
export class OrderActivatedListener {
    private readonly logger = new Logger(OrderActivatedListener.name);

    constructor(
        private readonly taskEngine: TaskEngineService,
        private readonly orderRepo: OrderRepository,
        private readonly taskRepo: TaskRepository,
        private readonly jobRepo: TaskGenerationJobRepository,
    ) { }

    @OnEvent('order.activated')
    async handleOrderActivated(payload: OrderActivatedEventPayload) {
        this.logger.log(
            `Handling 'order.activated' event for Order '${payload.orderId}'. Total required: ${payload.totalTasksRequired}.`,
        );

        try {
            const order = await this.orderRepo.findById(payload.orderId);
            if (!order) {
                this.logger.error(`Order '${payload.orderId}' not found during task generation event handling.`);
                return;
            }

            // Protection Pillar 5: Lock financial reward snapshot from order/payload (ZERO live catalog lookup)
            const rewardAmount = payload.workerRewardSnapshot || Number(order.workerRewardSnapshot || order.rewardPerTask || 5);

            // Protection Pillar 3: Get or create durable TaskGenerationJob for progress tracking & crash recovery
            let job = await this.jobRepo.findByOrderId(payload.orderId);
            if (!job) {
                job = await this.jobRepo.create({
                    orderId: payload.orderId,
                    totalTasksRequired: payload.totalTasksRequired,
                    generatedTasksCount: 0,
                    workerRewardSnapshot: rewardAmount,
                    status: TaskGenerationJobStatus.PROCESSING,
                });
            } else if (job.status === TaskGenerationJobStatus.COMPLETED) {
                this.logger.log(`TaskGenerationJob for Order '${payload.orderId}' is ALREADY COMPLETED. Skipping generation.`);
                return;
            }

            // Update job status to PROCESSING
            await this.jobRepo.updateProgress(job.id, job.generatedTasksCount, TaskGenerationJobStatus.PROCESSING);

            // Protection Pillar 2: Idempotent & Deterministic Task Generation (Check existing task count)
            const existingTasks = await this.taskRepo.findByOrderId(payload.orderId);
            const startIndex = existingTasks.length;

            if (startIndex >= payload.totalTasksRequired) {
                this.logger.log(
                    `Order '${payload.orderId}' already has ${startIndex}/${payload.totalTasksRequired} tasks created. Marking job as COMPLETED.`,
                );
                await this.jobRepo.updateProgress(job.id, startIndex, TaskGenerationJobStatus.COMPLETED);
                return;
            }

            this.logger.log(
                `Generating tasks for Order '${payload.orderId}' from index ${startIndex} to ${payload.totalTasksRequired}...`,
            );

            // Resume task generation loop starting from startIndex
            for (let i = startIndex; i < payload.totalTasksRequired; i++) {
                const taskRequirements = {
                    ...(order.requirements || {}),
                    sequenceIndex: i, // Deterministic sequence index for task deduplication
                    orderIdSequence: `${payload.orderId}_task_${i + 1}`,
                };

                await this.taskEngine.createTask({
                    orderId: payload.orderId,
                    campaignId: payload.orderId,
                    taskType: payload.serviceCode || order.taskType,
                    requirements: taskRequirements,
                    rewardAmount, // Locked snapshot value!
                });

                // Update job progress in DB periodically or after each task
                if ((i + 1) % 10 === 0 || i + 1 === payload.totalTasksRequired) {
                    await this.jobRepo.updateProgress(job.id, i + 1, TaskGenerationJobStatus.PROCESSING);
                }
            }

            // Mark job as COMPLETED
            await this.jobRepo.updateProgress(job.id, payload.totalTasksRequired, TaskGenerationJobStatus.COMPLETED);
            this.logger.log(`Successfully completed idempotent task generation for Order '${payload.orderId}'. Total: ${payload.totalTasksRequired}.`);
        } catch (error) {
            this.logger.error(
                `Error generating tasks for activated Order '${payload.orderId}': ${error.message}`,
                error.stack,
            );

            const job = await this.jobRepo.findByOrderId(payload.orderId);
            if (job) {
                await this.jobRepo.updateProgress(job.id, job.generatedTasksCount, TaskGenerationJobStatus.FAILED, error.message);
            }
        }
    }
}
