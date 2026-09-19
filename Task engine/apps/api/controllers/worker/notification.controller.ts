import {
    Controller,
    Get,
    Patch,
    Post,
    Put,
    Delete,
    Body,
    Param,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { NotificationRepository } from '../../../../shared/database/repositories/notification.repository';
import { UserRepository } from '../../../../shared/database/repositories/user.repository';
import { Roles } from '../../../../shared/auth/decorators/roles.decorator';
import { CurrentUser } from '../../../../shared/auth/decorators/current-user.decorator';
import { UserRole, User } from '../../../../shared/database/entities/user.entity';

import { TaskEngineService } from '../../../../task-engine/task-engine.service';
import { extractTaskIdentity } from '../../../../shared/common/utils/task-identity.util';

@ApiTags('Worker - Notifications')
@Roles(UserRole.WORKER)
@ApiBearerAuth('bearer')
@Controller('worker/notifications')
export class WorkerNotificationController {
    constructor(
        private readonly notificationRepo: NotificationRepository,
        private readonly userRepo: UserRepository,
        private readonly taskEngine: TaskEngineService,
    ) { }

    private isNotificationExcluded(
        notif: any,
        excludedPackageIds: Set<string>,
        excludedUrls: Set<string>,
    ): boolean {
        const data = notif.data || {};
        const packageId = data.packageId;
        const normalizedUrl = data.normalizedUrl;
        const targetUrl = data.targetUrl || data.url;

        if (packageId && excludedPackageIds.has(packageId.toLowerCase())) {
            return true;
        }
        if (normalizedUrl && excludedUrls.has(normalizedUrl)) {
            return true;
        }
        if (targetUrl || packageId) {
            const identity = extractTaskIdentity(data);
            if (identity.packageId && excludedPackageIds.has(identity.packageId.toLowerCase())) {
                return true;
            }
            if (identity.normalizedUrl && excludedUrls.has(identity.normalizedUrl)) {
                return true;
            }
        }
        return false;
    }

    @Get()
    @ApiOperation({ summary: 'Get worker notifications' })
    async getNotifications(@CurrentUser() user: User) {
        const notifications = await this.notificationRepo.findByUserId(user.id);
        const { packageIds, normalizedUrls } = await this.taskEngine.getWorkerExcludedEntities(user.id, user.email);

        const filteredNotifications = notifications.filter(
            (notif) => !this.isNotificationExcluded(notif, packageIds, normalizedUrls),
        );

        return {
            success: true,
            notifications: filteredNotifications,
            total: filteredNotifications.length,
        };
    }

    @Get('unread-count')
    @ApiOperation({ summary: 'Get unread notification count' })
    async getUnreadCount(@CurrentUser() user: User) {
        const notifications = await this.notificationRepo.findByUserId(user.id, 100);
        const { packageIds, normalizedUrls } = await this.taskEngine.getWorkerExcludedEntities(user.id, user.email);

        const count = notifications.filter(
            (notif) => !notif.isRead && !this.isNotificationExcluded(notif, packageIds, normalizedUrls),
        ).length;

        return {
            success: true,
            unreadCount: count,
        };
    }

    @Patch(':id/read')
    @ApiOperation({ summary: 'Mark single notification as read' })
    async markAsRead(@Param('id') id: string) {
        await this.notificationRepo.markAsRead(id);
        return {
            success: true,
            message: 'Notification marked as read',
        };
    }

    @Post('read-all')
    @ApiOperation({ summary: 'Mark all worker notifications as read' })
    async markAllAsRead(@CurrentUser() user: User) {
        await this.notificationRepo.markAllAsRead(user.id);
        return {
            success: true,
            message: 'All notifications marked as read',
        };
    }

    @Put('device-token')
    @ApiOperation({ summary: 'Update worker device FCM token' })
    async updateDeviceToken(@CurrentUser() user: User, @Body() body: { deviceToken: string }) {
        if (body?.deviceToken) {
            const currentMetadata = user.metadata || {};
            await this.userRepo.update(user.id, {
                metadata: {
                    ...currentMetadata,
                    deviceToken: body.deviceToken,
                    fcmToken: body.deviceToken,
                    tokenUpdatedAt: new Date().toISOString(),
                },
            });
        }
        return {
            success: true,
            message: 'Device token registered successfully',
        };
    }

    @Delete(':id')
    @ApiOperation({ summary: 'Delete single notification' })
    async deleteNotification(@Param('id') id: string) {
        await this.notificationRepo.delete(id);
        return {
            success: true,
            message: 'Notification deleted successfully',
        };
    }

    @Delete()
    @ApiOperation({ summary: 'Clear all notifications for worker' })
    async clearAllNotifications(@CurrentUser() user: User) {
        await this.notificationRepo.deleteAllForUser(user.id);
        return {
            success: true,
            message: 'All notifications cleared successfully',
        };
    }
}
