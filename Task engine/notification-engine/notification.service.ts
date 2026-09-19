import { Injectable, Logger, Optional, Inject } from '@nestjs/common';
import { NotificationRepository } from '../shared/database/repositories/notification.repository';
import { UserRepository } from '../shared/database/repositories/user.repository';
import { WorkerRepository } from '../shared/database/repositories/worker.repository';
import { NotificationType } from '../shared/database/entities/notification.entity';
import { User, UserRole } from '../shared/database/entities/user.entity';
import { FirebaseAdminService } from '../shared/services/firebase-admin.service';
import * as admin from 'firebase-admin';

/**
 * Notification Engine
 * Dispatches real-time Push Notifications (FCM), saves in-app notifications
 * to MySQL and Firestore for workers and buyers.
 */
@Injectable()
export class NotificationEngineService {
    private readonly logger = new Logger(NotificationEngineService.name);

    constructor(
        private readonly notificationRepo: NotificationRepository,
        private readonly userRepo: UserRepository,
        private readonly workerRepo: WorkerRepository,
        @Optional() @Inject(FirebaseAdminService) private readonly firebaseAdmin?: FirebaseAdminService,
    ) { }

    async sendNotification(
        userId: string,
        message: string,
        type: string = 'GENERAL',
        metadata: Record<string, any> = {},
    ): Promise<void> {
        this.logger.log(`🔔 [NOTIFICATION] To: ${userId} | Type: ${type} | Message: ${message}`);

        try {
            // 1. Resolve User
            const user = await this.resolveUser(userId);

            // 2. Format title, body, entityType
            const { title, body, entityType, entityId, notificationType } = this.formatNotification(type, message, metadata);

            // 3. Save to MySQL notifications table for In-App Notification Center
            const mysqlUserId = user?.id || userId;
            try {
                await this.notificationRepo.create({
                    userId: mysqlUserId,
                    type: notificationType,
                    title,
                    message: body,
                    entityType,
                    entityId,
                    data: metadata,
                    isRead: false,
                });

                // If original identifier is a Firestore UID or email different from user.id, also insert so queries match
                if (userId && userId !== mysqlUserId) {
                    await this.notificationRepo.create({
                        userId,
                        type: notificationType,
                        title,
                        message: body,
                        entityType,
                        entityId,
                        data: metadata,
                        isRead: false,
                    });
                }
            } catch (dbErr: any) {
                this.logger.warn(`Failed to save notification to MySQL: ${dbErr.message}`);
            }

            // 4. Save to Firestore notifications collection for real-time history
            if (this.firebaseAdmin) {
                try {
                    const fsUid = user?.metadata?.firebaseUid || user?.metadata?.uid || (userId.length > 20 && !userId.includes('-') ? userId : null);
                    await this.firebaseAdmin.firestore.collection('notifications').add({
                        userId: mysqlUserId,
                        firebaseUid: fsUid || mysqlUserId,
                        target: mysqlUserId,
                        email: user?.email || '',
                        type,
                        title,
                        body,
                        data: metadata,
                        isRead: false,
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    });

                    if (fsUid) {
                        await this.firebaseAdmin.firestore.collection('users').doc(fsUid).collection('notifications').add({
                            type,
                            title,
                            body,
                            data: metadata,
                            isRead: false,
                            createdAt: admin.firestore.FieldValue.serverTimestamp(),
                        });
                    }
                } catch (fsErr: any) {
                    this.logger.warn(`Failed to save notification to Firestore: ${fsErr.message}`);
                }
            }

            // 5. Resolve FCM Device Token & Dispatch High-Priority Push Notification
            if (this.firebaseAdmin) {
                const fcmToken = await this.resolveFcmToken(user, userId);
                if (fcmToken) {
                    const dataPayload: Record<string, string> = {
                        type: String(type),
                        click_action: 'FLUTTER_NOTIFICATION_CLICK',
                        title: String(title),
                        body: String(body),
                        taskId: String(metadata?.taskId || entityId || ''),
                        submissionId: String(metadata?.submissionId || ''),
                        withdrawalId: String(metadata?.withdrawalId || entityId || ''),
                        amount: String(metadata?.amount || ''),
                        transactionId: String(metadata?.transactionId || ''),
                        createdAt: new Date().toISOString(),
                    };

                    const sent = await this.firebaseAdmin.sendDirectPushNotification(
                        fcmToken,
                        title,
                        body,
                        dataPayload,
                    );
                    if (sent) {
                        this.logger.log(`📱 [PUSH DELIVERED] Successfully sent '${type}' push to ${user?.email || userId}`);
                    }
                } else {
                    this.logger.warn(`⚠️ [NO FCM TOKEN] Could not find FCM device token for worker ${userId} (${user?.email || 'unknown'})`);
                }
            }
        } catch (err: any) {
            this.logger.error(`Error in sendNotification for ${userId}: ${err.message}`, err.stack);
        }
    }

    async sendBulkNotifications(
        userIds: string[],
        message: string,
        type: string = 'BULK',
        metadata: Record<string, any> = {},
    ): Promise<void> {
        this.logger.log(`🔔 [BULK NOTIFICATION] To ${userIds.length} users | Type: ${type}`);
        for (const userId of userIds) {
            await this.sendNotification(userId, message, type, metadata);
        }
    }

    private async resolveUser(identifier: string): Promise<User | null> {
        if (!identifier) return null;

        // 1. Direct ID lookup in users table
        try {
            const byId = await this.userRepo.findById(identifier);
            if (byId) return byId;
        } catch (_) { }

        // 2. Email lookup
        if (identifier.includes('@')) {
            try {
                const byEmail = await this.userRepo.findByEmail(identifier);
                if (byEmail) return byEmail;
            } catch (_) { }
        }

        // 3. Worker profile lookup
        try {
            const worker = await this.workerRepo.findById(identifier);
            if (worker?.userId) {
                const byWorkerUserId = await this.userRepo.findById(worker.userId);
                if (byWorkerUserId) return byWorkerUserId;
            }
        } catch (_) { }

        // 4. Look up in metadata or custom query in users table
        try {
            const workers = await this.userRepo.findByRole(UserRole.WORKER);
            for (const w of workers) {
                if (
                    w.id === identifier ||
                    w.email === identifier ||
                    w.metadata?.firebaseUid === identifier ||
                    w.metadata?.uid === identifier
                ) {
                    return w;
                }
            }
        } catch (_) { }

        return null;
    }

    private async resolveFcmToken(user: User | null, rawIdentifier: string): Promise<string | null> {
        // 1. From user.metadata
        const metaToken = user?.metadata?.fcmToken || user?.metadata?.deviceToken;
        if (metaToken && typeof metaToken === 'string' && metaToken.length > 20) {
            return metaToken;
        }

        // 2. From Firestore users collection
        if (this.firebaseAdmin) {
            const lookupKeys = [
                rawIdentifier,
                user?.metadata?.firebaseUid,
                user?.metadata?.uid,
                user?.id,
                user?.email,
            ].filter(Boolean);

            for (const key of lookupKeys) {
                try {
                    const fsUser = await this.firebaseAdmin.getFirestoreUser(key as string);
                    if (fsUser?.fcmToken && typeof fsUser.fcmToken === 'string' && fsUser.fcmToken.length > 20) {
                        // Cache back to user.metadata in MySQL for speed
                        if (user?.id) {
                            try {
                                await this.userRepo.update(user.id, {
                                    metadata: {
                                        ...(user.metadata || {}),
                                        fcmToken: fsUser.fcmToken,
                                        deviceToken: fsUser.fcmToken,
                                    },
                                });
                            } catch (_) { }
                        }
                        return fsUser.fcmToken;
                    }
                } catch (_) { }
            }
        }

        return null;
    }

    private formatNotification(type: string, message: string, metadata: Record<string, any> = {}): {
        title: string;
        body: string;
        entityType?: string;
        entityId?: string;
        notificationType: NotificationType;
    } {
        const normType = (type || 'GENERAL').toUpperCase();

        let title = '🔔 Task Platform';
        let body = message;
        let entityType: string | undefined;
        let entityId: string | undefined;
        let notificationType: NotificationType = NotificationType.ORDER_PROGRESS;

        if (normType.includes('TASK_APPROVED')) {
            title = '🎉 Task Approved & Reward Credited!';
            body = message || 'Your task submission has been approved! The reward has been added to your wallet.';
            entityType = 'TASK';
            entityId = metadata.taskId || metadata.submissionId;
            notificationType = NotificationType.TASK_APPROVED;
        } else if (normType.includes('TASK_REJECTED')) {
            title = '❌ Task Submission Rejected';
            body = message || 'Your task submission was not approved. Please check instructions and retry.';
            entityType = 'TASK';
            entityId = metadata.taskId || metadata.submissionId;
            notificationType = NotificationType.TASK_REJECTED;
        } else if (normType.includes('PAYOUT_COMPLETED') || normType.includes('WITHDRAWAL_PAID')) {
            title = '💸 Payout Successful! Bank Transfer Complete';
            body = message || `Payout of ₹${Number(metadata.amount || 0).toFixed(2)} has been successfully transferred to your account!`;
            entityType = 'WITHDRAWAL';
            entityId = metadata.withdrawalId;
            notificationType = NotificationType.WITHDRAWAL_PAID;
        } else if (normType.includes('PAYOUT_REJECTED') || normType.includes('WITHDRAWAL_REJECTED')) {
            title = '❌ Payout Request Rejected';
            body = message || 'Your withdrawal request was rejected and funds have been refunded to your wallet.';
            entityType = 'WITHDRAWAL';
            entityId = metadata.withdrawalId;
            notificationType = NotificationType.WITHDRAWAL_REQUESTED;
        } else if (normType.includes('WITHDRAWAL_REQUESTED')) {
            title = '⏳ Withdrawal Request Submitted';
            body = message || 'Your payout request is being processed by our finance team.';
            entityType = 'WITHDRAWAL';
            entityId = metadata.withdrawalId;
            notificationType = NotificationType.WITHDRAWAL_REQUESTED;
        } else if (normType.includes('TASK_ASSIGNED')) {
            title = '🎯 New Task Assigned to You';
            entityType = 'TASK';
            entityId = metadata.taskId;
            notificationType = NotificationType.TASK_ASSIGNED;
        } else if (normType.includes('EARNING_POSTED')) {
            title = '💰 Cash Reward Credited!';
            body = message || 'Reward credited to your wallet balance.';
            entityType = 'EARNING';
            entityId = metadata.taskId;
            notificationType = NotificationType.EARNING_POSTED;
        }

        return { title, body, entityType, entityId, notificationType };
    }
}
