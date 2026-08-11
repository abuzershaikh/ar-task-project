import { Injectable, Logger } from '@nestjs/common';
import { NotificationRepository } from '../database/repositories/notification.repository';
import { NotificationType, Notification } from '../database/entities/notification.entity';

export interface SendNotificationParams {
    userId: string;
    type: NotificationType;
    title: string;
    message: string;
    entityType?: string;
    entityId?: string;
    data?: any;
}

@Injectable()
export class NotificationService {
    private readonly logger = new Logger(NotificationService.name);

    constructor(private readonly notificationRepo: NotificationRepository) { }

    async send(params: SendNotificationParams): Promise<Notification> {
        this.logger.log(`Sending notification ${params.type} to user ${params.userId}`);
        return this.notificationRepo.create({
            userId: params.userId,
            type: params.type,
            title: params.title,
            message: params.message,
            entityType: params.entityType,
            entityId: params.entityId,
            data: params.data,
            isRead: false,
        });
    }

    async getUserNotifications(userId: string, limit = 50): Promise<Notification[]> {
        return this.notificationRepo.findByUserId(userId, limit);
    }

    async getUnreadCount(userId: string): Promise<number> {
        return this.notificationRepo.countUnread(userId);
    }

    async markAsRead(notificationId: string): Promise<void> {
        await this.notificationRepo.markAsRead(notificationId);
    }

    async markAllAsRead(userId: string): Promise<void> {
        await this.notificationRepo.markAllAsRead(userId);
    }
}
