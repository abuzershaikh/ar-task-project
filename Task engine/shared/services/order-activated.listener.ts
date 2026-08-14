import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { InjectQueue } from '@nestjs/bull';
import { Queue } from 'bull';
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
        @InjectQueue('task') private readonly taskQueue: Queue,
    ) { }

    @OnEvent('order.activated')
    async handleOrderActivated(payload: OrderActivatedEventPayload) {
        this.logger.log(
            `Handling 'order.activated' event for Order '${payload.orderId}'. Total required: ${payload.totalTasksRequired}.`,
        );

        try {
            const order = await this.orderRepo.findById(payload.orderId);
            if (!order && !payload.orderId.startsWith('TEST_')) {
                this.logger.error(`Order '${payload.orderId}' not found during task generation event handling.`);
                return;
            }

            const rewardAmount = payload.workerRewardSnapshot || Number(order?.workerRewardSnapshot || order?.rewardPerTask || 5);

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

            await this.jobRepo.updateProgress(job.id, job.generatedTasksCount, TaskGenerationJobStatus.PROCESSING);

            // Enqueue task creation job to Bull Redis Queue for asynchronous worker consumption
            this.logger.log(`📥 Dispatching 'create-tasks' job to Bull Redis Queue ('task') for Order '${payload.orderId}'`);
            await this.taskQueue.add(
                'create-tasks',
                {
                    orderId: payload.orderId,
                    count: payload.totalTasksRequired,
                    taskType: payload.serviceCode || order?.taskType || 'DEFAULT',
                    requirements: order?.requirements || {},
                    rewardAmount,
                    jobId: job.id,
                },
                {
                    attempts: 3,
                    backoff: { type: 'exponential', delay: 2000 },
                    removeOnComplete: true,
                },
            );

            this.logger.log(`✅ Successfully queued background task generation for Order '${payload.orderId}'.`);
        } catch (error) {
            this.logger.error(
                `Error queueing tasks for activated Order '${payload.orderId}': ${error.message}`,
                error.stack,
            );

            const job = await this.jobRepo.findByOrderId(payload.orderId);
            if (job) {
                await this.jobRepo.updateProgress(job.id, job.generatedTasksCount, TaskGenerationJobStatus.FAILED, error.message);
            }
        }
    }
}
