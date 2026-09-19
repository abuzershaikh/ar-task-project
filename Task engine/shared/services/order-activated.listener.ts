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
import { UserRepository } from '../database/repositories/user.repository';
import { UserRole } from '../database/entities/user.entity';
import { AiGeneratorService } from '../ai-generator/ai-generator.service';
import { sanitizeReviewText } from '../ai-generator/review-sanitizer';
import { FirebaseAdminService } from './firebase-admin.service';
import { PlayStoreScraperService } from './playstore-scraper.service';
import { extractTaskIdentity, resolveShortUrl } from '../common/utils/task-identity.util';

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
        private readonly userRepo: UserRepository,
        private readonly aiGeneratorService: AiGeneratorService,
        private readonly firebaseAdmin: FirebaseAdminService,
        private readonly playStoreScraper: PlayStoreScraperService,
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

            const rewardAmount = payload.workerRewardSnapshot || Number(order?.workerRewardSnapshot || order?.rewardPerTask || 0);

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

            const targetUrl = order?.requirements?.targetUrl || order?.requirements?.url || order?.requirements?.link || '';

            const isGoogleBusiness = serviceIdentifier.includes('GOOGLE_BUSINESS') ||
                serviceIdentifier.includes('GMB') ||
                serviceIdentifier.includes('GOOGLE_MAP') ||
                serviceIdentifier.includes('GMAP') ||
                (serviceCatalog?.category || '').toLowerCase().includes('google business') ||
                (serviceCatalog?.category || '').toLowerCase().includes('google maps') ||
                (serviceCatalog?.category || '').toLowerCase().includes('maps') ||
                (serviceCatalog?.name || '').toLowerCase().includes('google business') ||
                (serviceCatalog?.name || '').toLowerCase().includes('google maps') ||
                (targetUrl && (targetUrl.includes('maps.google.com') || targetUrl.includes('goo.gl/maps') || targetUrl.includes('maps.app.goo.gl') || targetUrl.includes('search.google.com/local')));

            const isPlayStore = !isGoogleBusiness && (
                serviceIdentifier.includes('PLAY') ||
                serviceIdentifier.includes('APP_REVIEW') ||
                serviceIdentifier.includes('GOOGLE_PLAY') ||
                serviceIdentifier.includes('INSTALL') ||
                serviceIdentifier.includes('APP_INSTALL') ||
                (serviceCatalog?.category || '').toLowerCase().includes('play') ||
                (serviceCatalog?.category || '').toLowerCase().includes('install') ||
                (serviceCatalog?.category || '').toLowerCase().includes('app') ||
                (serviceCatalog?.name || '').toLowerCase().includes('play store') ||
                (serviceCatalog?.name || '').toLowerCase().includes('app install') ||
                (serviceCatalog?.name || '').toLowerCase().includes('install') ||
                (targetUrl && (targetUrl.includes('play.google.com') || targetUrl.includes('market://')))
            );

            // CRITICAL: Ensure 'isInstagram' does NOT match 'APP_INSTALL' or words containing 'install'!!
            const isInstagram = !isPlayStore && !isGoogleBusiness && (
                serviceIdentifier.includes('INSTAGRAM') ||
                serviceIdentifier === 'INSTA' ||
                serviceIdentifier.startsWith('INSTA_') ||
                serviceIdentifier.endsWith('_INSTA') ||
                serviceIdentifier.includes('_INSTA_') ||
                serviceIdentifier.includes('IG_') ||
                serviceIdentifier.includes('_IG')
            );
            const isInstagramCombo = isInstagram && serviceIdentifier.includes('COMBO');
            const isYouTubeCombo = (serviceIdentifier.includes('YT') || serviceIdentifier.includes('YOUTUBE')) && serviceIdentifier.includes('COMBO');

            const isGoogleBusinessReview = isGoogleBusiness && (
                serviceIdentifier.includes('REVIEW') ||
                (serviceCatalog?.name || '').toLowerCase().includes('review') ||
                Boolean(serviceCatalog?.aiGeneratorEnabled) ||
                Boolean(order?.requirements?.aiGeneratorEnabled)
            );

            const isInstagramComboWithComments = isInstagramCombo && Boolean(
                order?.requirements?.aiGeneratorEnabled ||
                serviceCatalog?.aiGeneratorEnabled ||
                (Array.isArray(order?.requirements?.sampleComments) && order.requirements.sampleComments.length > 0)
            );

            const isCommentRequired = isInstagramComboWithComments || (!isInstagramCombo && (
                isGoogleBusinessReview ||
                (!isGoogleBusiness && (
                    Boolean(serviceCatalog?.aiGeneratorEnabled) ||
                    serviceIdentifier.includes('COMMENT') ||
                    isYouTubeCombo ||
                    serviceIdentifier.includes('REVIEW') ||
                    Boolean(order?.requirements?.aiGeneratorEnabled)
                ))
            ));

            const count = payload.totalTasksRequired;
            const topic = order?.requirements?.topic || order?.requirements?.customText || order?.requirements?.comment || '';
            const language = order?.requirements?.language || 'English';
            const tone = order?.requirements?.tone || 'natural';
            let appName = order?.requirements?.appName || order?.requirements?.businessName || '';
            let appIcon = order?.requirements?.appIcon || '';
            let packageId = order?.requirements?.packageId || '';

            // Auto-extract Google Play Store app icon & name for the specific targetUrl
            if (targetUrl && (isPlayStore || targetUrl.includes('play.google.com') || targetUrl.includes('id='))) {
                const pkg = this.playStoreScraper.extractPackageId(targetUrl);
                if (pkg) {
                    try {
                        const appInfo = await this.playStoreScraper.getAppMetadata(targetUrl);
                        if (appInfo && appInfo.success) {
                            if (appInfo.appIcon) appIcon = appInfo.appIcon;
                            if (appInfo.appName) appName = appInfo.appName;
                            packageId = appInfo.packageId || pkg;
                        }
                    } catch (err: any) {
                        this.logger.warn(`Could not scrape Play Store metadata for order ${payload.orderId}: ${err?.message}`);
                    }
                }
            }

            // 1. Gather any buyer sample comments/reviews sent with the order
            const rawSampleComments = order?.requirements?.sampleComments;
            const sampleComments: string[] = Array.isArray(rawSampleComments) 
                ? rawSampleComments.filter((c: any) => typeof c === 'string' && c.trim().length > 0) 
                : [];

            const generatorType = isGoogleBusiness
                ? 'google_business_review'
                : (isPlayStore ? 'playstore_review' : (isInstagram ? 'instagram_comment' : 'youtube_comment'));

            const minWords = order?.requirements?.minWords ? Math.max(4, order.requirements.minWords) : 15;
            const maxWords = order?.requirements?.maxWords ? Math.max(minWords, order.requirements.maxWords) : 45;

            let generatedComments: string[] = [];
            if (isCommentRequired) {
                if (sampleComments.length >= count) {
                    generatedComments = sampleComments.slice(0, count);
                } else {
                    const remainingNeeded = count - sampleComments.length;
                    this.logger.log(`🤖 Generating ${remainingNeeded} ${isGoogleBusiness ? 'Google Business reviews' : (isPlayStore ? 'Play Store reviews' : (isInstagram ? 'Instagram comments' : 'comments'))} for Order '${payload.orderId}' (App: "${appName}", Words: ${minWords}-${maxWords}, Topic: "${topic}", Lang: ${language}, Tone: ${tone})`);
                    let newlyGenerated: string[] = [];
                    try {
                        newlyGenerated = await this.aiGeneratorService.generateContentBatch(
                            generatorType,
                            remainingNeeded,
                            {
                                topic,
                                language,
                                tone,
                                uniqueness: true,
                                isAppReview: isPlayStore,
                                isGoogleBusiness,
                                isInstagram,
                                appName,
                                businessName: appName,
                                videoTitle: order?.requirements?.videoTitle || (!isPlayStore && !isGoogleBusiness ? (appName || '') : ''),
                                generatorType,
                                minWords,
                                maxWords,
                            } as any,
                        );
                    } catch (genErr) {
                        this.logger.error(`Error generating content batch: ${genErr.message}`);
                    }
                    generatedComments = [...sampleComments, ...newlyGenerated];
                }
            }

            // Hardcoded fallback template arrays removed - real AI comments or approved sampleComments are strictly used.

            const detectedPlatform = isGoogleBusiness
                ? 'google_business'
                : (isPlayStore
                    ? 'playstore'
                    : (isInstagram ? 'instagram' : (serviceIdentifier.includes('FACEBOOK') || serviceIdentifier.includes('FB') ? 'facebook' : (serviceIdentifier.includes('TELEGRAM') ? 'telegram' : 'youtube'))));

            const combinedRequirements = {
                ...(order?.requirements || {}),
                platform: detectedPlatform,
                serviceName: serviceCatalog?.name || order?.taskType || (isGoogleBusiness ? (isGoogleBusinessReview ? 'Google Business Review' : 'Google Business Rating') : (isPlayStore ? 'Play Store Review' : 'Task')),
                serviceDescription: serviceCatalog?.description || '',
                videoTutorialUrl: serviceCatalog?.videoTutorialUrl || order?.requirements?.videoTutorialUrl || '',
                audioGuideUrl: serviceCatalog?.audioGuideUrl || order?.requirements?.audioGuideUrl || '',
                adminInstructions: serviceCatalog?.adminInstructions || serviceCatalog?.description || order?.requirements?.instructions || '',
                targetUrl,
                watchTimeSeconds: Number(order?.requirements?.watchTimeSeconds || serviceCatalog?.watchtimeSeconds || 0),
                videoDurationSeconds: Number(order?.requirements?.videoDurationSeconds || 0),
                proofType: order?.requirements?.proofType || 'SCREENSHOT',
                actions: {
                    rating5Star: isPlayStore || isGoogleBusiness || serviceIdentifier.includes('RATING') || serviceIdentifier.includes('REVIEW'),
                    review: (isPlayStore || isGoogleBusiness) && isCommentRequired,
                    googleRating: isGoogleBusiness,
                    googleReview: isGoogleBusiness && isCommentRequired,
                    like: serviceIdentifier.includes('LIKE') || serviceIdentifier.includes('COMBO'),
                    subscribe: !isInstagram && !isGoogleBusiness && (serviceIdentifier.includes('SUBSCRIBE') || isYouTubeCombo),
                    follow: isInstagram && (serviceIdentifier.includes('FOLLOW') || isInstagramCombo),
                    comment: isCommentRequired,
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
                    let rawAssigned = '';
                    if (generatedComments[i] && generatedComments[i].trim().length > 0) {
                        rawAssigned = generatedComments[i].trim();
                    } else if (sampleComments.length > 0) {
                        rawAssigned = sampleComments[i % sampleComments.length].trim();
                    } else {
                        rawAssigned = topic || order?.requirements?.customText || '';
                    }
                    const assignedComment = sanitizeReviewText(rawAssigned);

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
                        ? sanitizeReviewText(unit.generatedContent || (sampleComments.length > 0 ? sampleComments[i % sampleComments.length] : (topic || '')))
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
                        appIcon: appIcon || combinedRequirements?.appIcon,
                        appName: appName || combinedRequirements?.appName,
                        packageId: packageId || combinedRequirements?.packageId,
                    };

                    await this.taskEngine.createTask({
                        orderId: payload.orderId,
                        campaignId: payload.orderId,
                        orderUnitId: unit.id,
                        taskType,
                        requirements: taskReqs,
                        metadata: {
                            appIcon: appIcon || combinedRequirements?.appIcon,
                            appName: appName || combinedRequirements?.appName,
                            packageId: packageId || combinedRequirements?.packageId,
                            rewardSnapshot: {
                                totalReward: rewardAmount,
                                baseReward: rewardAmount,
                                currency: 'INR',
                            },
                        },
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

                const category = serviceCatalog?.category || (payload.serviceCode.toLowerCase().includes('instagram') ? 'Instagram' : (payload.serviceCode.toLowerCase().includes('install') || payload.serviceCode.toLowerCase().includes('app') ? 'App Install' : 'General'));

                // 🖼️ Resolve Platform / App Icon for Rich Notification Display
                let notificationIcon = '';
                const sLower = `${payload.serviceCode} ${serviceTitle} ${category}`.toLowerCase();
                const specificAppIcon = appIcon || combinedRequirements?.appIcon || '';
                const assetBaseUrl = (process.env.APP_URL || 'http://65.20.77.112:3000') + '/api/v1/assets/icons';
                if (specificAppIcon && specificAppIcon.startsWith('http')) {
                    notificationIcon = specificAppIcon;
                } else if (isGoogleBusiness || sLower.includes('business') || sLower.includes('maps')) {
                    notificationIcon = `${assetBaseUrl}/google_maps`;
                } else if (isPlayStore || sLower.includes('install') || sLower.includes('app') || sLower.includes('playstore') || sLower.includes('google')) {
                    notificationIcon = `${assetBaseUrl}/playstore`;
                } else if (isInstagram || (sLower.includes('instagram') && !sLower.includes('install'))) {
                    notificationIcon = `${assetBaseUrl}/instagram`;
                } else if (sLower.includes('youtube') || sLower.includes('yt')) {
                    notificationIcon = `${assetBaseUrl}/youtube`;
                } else if (sLower.includes('facebook') || sLower.includes('fb')) {
                    notificationIcon = `${assetBaseUrl}/facebook`;
                } else if (sLower.includes('telegram')) {
                    notificationIcon = `${assetBaseUrl}/telegram`;
                } else if (sLower.includes('twitter') || sLower.includes(' x ')) {
                    notificationIcon = `${assetBaseUrl}/twitter`;
                } else {
                    notificationIcon = `${assetBaseUrl}/playstore`;
                }

                // 1. Resolve task identity (expand short URLs like maps.app.goo.gl if present)
                let resolvedTargetUrl = targetUrl;
                if (targetUrl && (targetUrl.includes('goo.gl') || targetUrl.includes('bit.ly') || targetUrl.includes('tinyurl.com'))) {
                    try {
                        resolvedTargetUrl = await resolveShortUrl(targetUrl, 3000);
                    } catch (_) {}
                }

                const taskIdentity = extractTaskIdentity({
                    requirements: combinedRequirements,
                    metadata: { appName, appIcon, targetUrl: resolvedTargetUrl, packageId },
                    targetUrl: resolvedTargetUrl,
                    packageId,
                });

                // 2. Identify workers who have ALREADY completed/held a task for this packageId or normalizedUrl
                const excludedWorkerIds = new Set<string>();
                if (taskIdentity.packageId || taskIdentity.normalizedUrl) {
                    try {
                        const excluded = await this.taskRepo.findWorkerIdsWithPackageOrUrl(
                            taskIdentity.packageId,
                            taskIdentity.normalizedUrl,
                        );
                        for (const id of excluded) {
                            excludedWorkerIds.add(id.toLowerCase().trim());
                        }
                    } catch (e) {
                        this.logger.warn(`Error finding excluded workers for task notification: ${e.message}`);
                    }
                }

                // 3. Resolve eligible workers who have device push tokens
                let eligibleTokens: string[] | undefined = undefined;
                if (taskIdentity.packageId || taskIdentity.normalizedUrl) {
                    try {
                        const allWorkers = await this.userRepo.findByRole(UserRole.WORKER);
                        const tokenList: string[] = [];
                        for (const w of allWorkers) {
                            const wId = (w.id || '').toLowerCase().trim();
                            const wEmail = (w.email || '').toLowerCase().trim();
                            if (excludedWorkerIds.has(wId) || (wEmail && excludedWorkerIds.has(wEmail))) {
                                continue; // 🚫 SUPPRESS! Worker has already done this app/URL
                            }
                            const meta = (w.metadata as any) || {};
                            const token = meta.fcmToken || meta.deviceToken;
                            if (token && typeof token === 'string' && token.length > 20) {
                                tokenList.push(token);
                            }
                        }
                        eligibleTokens = tokenList;
                        this.logger.log(`🎯 [NOTIFICATION FILTER] Total workers: ${allWorkers.length}, Excluded (already completed): ${excludedWorkerIds.size}, Eligible tokens: ${eligibleTokens.length}`);
                    } catch (e) {
                        this.logger.warn(`Error resolving eligible worker tokens: ${e.message}`);
                    }
                }

                await this.firebaseAdmin.sendTaskBroadcastNotification({
                    title: notificationTitle,
                    body: notificationBody,
                    taskId: targetTaskId,
                    orderId: payload.orderId,
                    reward: rewardAmount,
                    serviceCode: payload.serviceCode,
                    category,
                    icon: notificationIcon,
                    imageUrl: notificationIcon,
                    appIcon: specificAppIcon || notificationIcon,
                    appName: appName || combinedRequirements?.appName || '',
                    targetUrl: targetUrl || '',
                    targetTokens: eligibleTokens,
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
                        category,
                        icon: notificationIcon,
                        imageUrl: notificationIcon,
                        appIcon: specificAppIcon || notificationIcon,
                        appName: appName || combinedRequirements?.appName || '',
                        targetUrl: targetUrl || '',
                        packageId: taskIdentity.packageId || packageId || '',
                        normalizedUrl: taskIdentity.normalizedUrl || '',
                        type: 'NEW_TASK',
                    },
                });

                // Persist for buyer notification feed
                if (payload.buyerId) {
                    try {
                        await this.notificationRepo.create({
                            userId: payload.buyerId,
                            type: NotificationType.ORDER_PROGRESS,
                            title: `Campaign Live: ${serviceTitle}`,
                            message: `Your campaign for "${appName || serviceTitle}" (Order #${payload.orderId.slice(0, 8)}) with ${payload.totalTasksRequired} tasks is active and dispatching to verified human users.`,
                            entityType: 'ORDER',
                            entityId: payload.orderId,
                            data: {
                                orderId: payload.orderId,
                                serviceCode: payload.serviceCode,
                                totalTasks: payload.totalTasksRequired,
                                rewardAmount,
                            },
                            isRead: false,
                        });
                    } catch (buyerNotifErr: any) {
                        this.logger.warn(`Buyer notification creation warning: ${buyerNotifErr?.message}`);
                    }
                }
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
