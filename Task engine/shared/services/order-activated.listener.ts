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
import { OrderUnitRepository } from '../database/repositories/order-unit.repository';
import { NotificationRepository } from '../database/repositories/notification.repository';
import { NotificationType } from '../database/entities/notification.entity';
import { AiGeneratorService } from '../ai-generator/ai-generator.service';
import { FirebaseAdminService } from './firebase-admin.service';

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
        private readonly orderUnitRepo: OrderUnitRepository,
        private readonly notificationRepo: NotificationRepository,
        private readonly aiGeneratorService: AiGeneratorService,
        private readonly firebaseAdmin: FirebaseAdminService,
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

            const rawIdentifier = payload.serviceCode || order?.serviceCode || order?.taskType || '';
            const serviceIdentifier = rawIdentifier.toUpperCase();
            const serviceCatalog = rawIdentifier
                ? (await this.serviceCatalogRepo.findByCode(rawIdentifier) || await this.serviceCatalogRepo.findById(rawIdentifier))
                : null;

            const isCommentRequired = Boolean(serviceCatalog?.aiGeneratorEnabled) ||
                serviceIdentifier.includes('COMMENT') ||
                serviceIdentifier.includes('COMBO') ||
                serviceIdentifier.includes('REVIEW') ||
                Boolean(order?.requirements?.aiGeneratorEnabled);

            const count = payload.totalTasksRequired;
            const targetUrl = order?.requirements?.targetUrl || order?.requirements?.url || order?.requirements?.link || '';
            const topic = order?.requirements?.topic || order?.requirements?.customText || order?.requirements?.comment || '';
            const language = order?.requirements?.language || 'English';
            const tone = order?.requirements?.tone || 'natural';

            // 1. Gather any buyer sample comments sent with the order
            const rawSampleComments = order?.requirements?.sampleComments;
            const sampleComments: string[] = Array.isArray(rawSampleComments) 
                ? rawSampleComments.filter((c: any) => typeof c === 'string' && c.trim().length > 0) 
                : [];

            let generatedComments: string[] = [];
            if (isCommentRequired) {
                if (sampleComments.length >= count) {
                    generatedComments = sampleComments.slice(0, count);
                } else {
                    const remainingNeeded = count - sampleComments.length;
                    this.logger.log(`🤖 Generating ${remainingNeeded} comments for Order '${payload.orderId}' (Topic: "${topic}", Lang: ${language}, Tone: ${tone})`);
                    let newlyGenerated: string[] = [];
                    try {
                        newlyGenerated = await this.aiGeneratorService.generateContentBatch(
                            'youtube_comment',
                            remainingNeeded,
                            { topic, language, tone, uniqueness: true },
                        );
                    } catch (genErr) {
                        this.logger.error(`Error generating content batch: ${genErr.message}`);
                    }
                    generatedComments = [...sampleComments, ...newlyGenerated];
                }
            }

            const fallbackTemplates = [
                topic ? `Really good points made on ${topic}, very informative!` : 'Great video, keep up the fantastic work!',
                topic ? `Loved the breakdown about ${topic}. Very helpful!` : 'Awesome explanation, really enjoyed this video!',
                topic ? `Super informative video regarding ${topic}. Thanks for sharing!` : 'Very helpful and well explained!',
                topic ? `The explanation on ${topic} is so clear and precise.` : 'Thanks for sharing this, learned a lot!',
                topic ? `Great insights on ${topic}. Subscribed for more!` : 'Nicely done! Looking forward to more content.',
            ];

            const combinedRequirements = {
                ...(order?.requirements || {}),
                platform: 'youtube',
                serviceName: serviceCatalog?.name || order?.taskType || 'YouTube Task',
                serviceDescription: serviceCatalog?.description || '',
                videoTutorialUrl: serviceCatalog?.videoTutorialUrl || order?.requirements?.videoTutorialUrl || '',
                audioGuideUrl: serviceCatalog?.audioGuideUrl || order?.requirements?.audioGuideUrl || '',
                adminInstructions: serviceCatalog?.adminInstructions || serviceCatalog?.description || order?.requirements?.instructions || '',
                targetUrl,
                watchTimeSeconds: order?.requirements?.watchTimeSeconds || serviceCatalog?.watchtimeSeconds || 0,
                proofType: order?.requirements?.proofType || 'SCREENSHOT',
                actions: {
                    like: serviceIdentifier.includes('LIKE') || serviceIdentifier.includes('COMBO'),
                    subscribe: serviceIdentifier.includes('SUBSCRIBE') || serviceIdentifier.includes('COMBO'),
                    comment: isCommentRequired || serviceIdentifier.includes('COMMENT') || serviceIdentifier.includes('COMBO'),
                },
            };

            const taskType = payload.serviceCode || order?.taskType || 'DEFAULT';

            // Direct guaranteed task & order_unit generation in MySQL
            const existingTasks = await this.taskRepo.findByOrderId(payload.orderId);
            const generatedCount = existingTasks.length;

            if (generatedCount < count) {
                this.logger.log(`Creating ${count - generatedCount} tasks and order_units directly for Order '${payload.orderId}'`);
                
                const unitsToCreate = [];
                for (let i = generatedCount; i < count; i++) {
                    const assignedComment = (generatedComments[i] && generatedComments[i].trim().length > 0)
                        ? generatedComments[i].trim()
                        : fallbackTemplates[i % fallbackTemplates.length];

                    unitsToCreate.push({
                        orderId: payload.orderId,
                        unitNumber: i + 1,
                        targetUrl,
                        generatedContent: isCommentRequired ? assignedComment : (order?.requirements?.customText || null),
                        status: 'PENDING',
                    });
                }

                const savedUnits = await this.orderUnitRepo.createBatch(unitsToCreate);

                for (let i = 0; i < savedUnits.length; i++) {
                    const unit = savedUnits[i];
                    const finalComment = isCommentRequired
                        ? (unit.generatedContent || fallbackTemplates[i % fallbackTemplates.length])
                        : (order?.requirements?.customText || '');

                    const taskReqs = {
                        ...combinedRequirements,
                        unitNumber: unit.unitNumber,
                        orderUnitId: unit.id,
                        commentText: finalComment,
                        comment_text: finalComment,
                        comment: finalComment,
                        customText: finalComment,
                        sequenceIndex: generatedCount + i,
                        orderIdSequence: `${payload.orderId}_task_${generatedCount + i + 1}`,
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
            const unitLabel = this.getGenericUnitName(payload.serviceCode, serviceCatalog?.name, count);
            this.logger.log(`✅ ${count} ${unitLabel} and worker tasks generated in MySQL for Order '${payload.orderId}'.`);

            // 📢 Broadcast Instant Push Notification to Workers (without revealing buyer quantity)
            try {
                const serviceTitle = serviceCatalog?.name || payload.serviceCode.replace(/_/g, ' ');
                const notificationTitle = `🎉 New Task Available! Earn ₹${rewardAmount}`;
                const notificationBody = `New ${serviceTitle} task is now available. Complete now to earn instant cash!`;

                const allTasks = await this.taskRepo.findByOrderId(payload.orderId);
                const targetTaskId = allTasks.length > 0 ? allTasks[0].id : payload.orderId;

                await this.firebaseAdmin.sendTaskBroadcastNotification({
                    title: notificationTitle,
                    body: notificationBody,
                    taskId: targetTaskId,
                    orderId: payload.orderId,
                    reward: rewardAmount,
                    serviceCode: payload.serviceCode,
                });

                // Persist in MySQL for worker in-app notification history
                await this.notificationRepo.create({
                    userId: 'ALL_WORKERS',
                    type: NotificationType.TASK_ASSIGNED,
                    title: notificationTitle,
                    message: notificationBody,
                    entityType: 'TASK',
                    entityId: targetTaskId,
                    data: {
                        taskId: targetTaskId,
                        orderId: payload.orderId,
                        reward: rewardAmount,
                        serviceCode: payload.serviceCode,
                        type: 'NEW_TASK',
                    },
                });
            } catch (pushErr) {
                this.logger.warn(`Push notification dispatch warning: ${pushErr.message}`);
            }

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

    private getGenericUnitName(serviceCode: string, name?: string, count = 1): string {
        const s = `${serviceCode} ${name || ''}`.toLowerCase();
        let singular = 'Task';
        let plural = 'Tasks';

        if (s.includes('sub') || s.includes('subscriber')) {
            singular = 'Subscriber';
            plural = 'Subscribers';
        } else if (s.includes('like')) {
            singular = 'Like';
            plural = 'Likes';
        } else if (s.includes('comment')) {
            singular = 'Comment';
            plural = 'Comments';
        } else if (s.includes('watch') || s.includes('view')) {
            singular = 'View';
            plural = 'Views';
        } else if (s.includes('follow')) {
            singular = 'Follower';
            plural = 'Followers';
        } else if (s.includes('install') || s.includes('download')) {
            singular = 'Install';
            plural = 'Installs';
        } else if (s.includes('review') || s.includes('rating')) {
            singular = 'Review';
            plural = 'Reviews';
        } else if (s.includes('share') || s.includes('repost')) {
            singular = 'Share';
            plural = 'Shares';
        } else if (s.includes('combo') || s.includes('engagement')) {
            singular = 'Engagement';
            plural = 'Engagements';
        }

        return count === 1 ? singular : plural;
    }
}
