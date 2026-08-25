import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { InjectQueue } from '@nestjs/bull';
import { Queue } from 'bull';
import { TaskEngineService } from '../../task-engine/task-engine.service';
import { OrderRepository } from '../database/repositories/order.repository';
import { TaskRepository } from '../database/repositories/task.repository';
import { TaskGenerationJobRepository } from '../database/repositories/task-generation-job.repository';
import { TaskGenerationJobStatus } from '../database/entities/task-generation-job.entity';

import { ServiceCatalogRepository } from '../database/repositories/service-catalog.repository';

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
        private readonly serviceCatalogRepo: ServiceCatalogRepository,
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

            const serviceIdentifier = payload.serviceCode || order?.serviceCode || order?.taskType;
            const serviceCatalog = serviceIdentifier
                ? (await this.serviceCatalogRepo.findByCode(serviceIdentifier) || await this.serviceCatalogRepo.findById(serviceIdentifier))
                : null;

            const combinedRequirements = {
                ...(order?.requirements || {}),
                serviceName: serviceCatalog?.name || order?.taskType || 'Task',
                serviceDescription: serviceCatalog?.description || '',
                videoTutorialUrl: serviceCatalog?.videoTutorialUrl || order?.requirements?.videoTutorialUrl || '',
                audioGuideUrl: serviceCatalog?.audioGuideUrl || order?.requirements?.audioGuideUrl || '',
                adminInstructions: serviceCatalog?.adminInstructions || serviceCatalog?.description || order?.requirements?.instructions || '',
                targetUrl: order?.requirements?.targetUrl || order?.requirements?.url || order?.requirements?.link || '',
                customText: order?.requirements?.customText || order?.requirements?.text || order?.requirements?.comment || '',
                watchTimeSeconds: order?.requirements?.watchTimeSeconds || serviceCatalog?.watchtimeSeconds || 0,
                proofType: order?.requirements?.proofType || 'SCREENSHOT',
            };

            const taskType = payload.serviceCode || order?.taskType || 'DEFAULT';
            const count = payload.totalTasksRequired;

            // Direct guaranteed task generation in MySQL
            const existingTasks = await this.taskRepo.findByOrderId(payload.orderId);
            const generatedCount = existingTasks.length;

            if (generatedCount < count) {
                this.logger.log(`Creating ${count - generatedCount} tasks directly for Order '${payload.orderId}'`);
                for (let i = generatedCount; i < count; i++) {
                    const taskReqs = {
                        ...combinedRequirements,
                        sequenceIndex: i,
                        orderIdSequence: `${payload.orderId}_task_${i + 1}`,
                    };

                    await this.taskEngine.createTask({
                        orderId: payload.orderId,
                        campaignId: payload.orderId,
                        taskType,
                        requirements: taskReqs,
                        rewardAmount,
                    });
                }
            }

            await this.jobRepo.updateProgress(job.id, count, TaskGenerationJobStatus.COMPLETED);
            this.logger.log(`✅ ${count} tasks generated in MySQL and available in task feed for Order '${payload.orderId}'.`);

            // Optional background queue notification
            try {
                await this.taskQueue.add(
                    'create-tasks',
                    {
                        orderId: payload.orderId,
                        count,
                        taskType,
                        requirements: combinedRequirements,
                        rewardAmount,
                        jobId: job.id,
                    },
                    {
                        attempts: 3,
                        backoff: { type: 'exponential', delay: 2000 },
                        removeOnComplete: true,
                    },
                );
            } catch (_) {}
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
