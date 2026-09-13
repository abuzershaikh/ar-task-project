import { Controller, Get, Patch, Param } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { NotificationService } from '../../../../shared/services/notification.service';
import { Roles } from '../../../../shared/auth/decorators/roles.decorator';
import { CurrentUser } from '../../../../shared/auth/decorators/current-user.decorator';
import { UserRole, User } from '../../../../shared/database/entities/user.entity';

@ApiTags('Buyer - Notifications')
@Roles(UserRole.BUYER)
@ApiBearerAuth('bearer')
@Controller('buyer/notifications')
export class BuyerNotificationController {
    constructor(private readonly notificationService: NotificationService) { }

    @Get()
    @ApiOperation({ summary: 'Get buyer notification feed' })
    async getNotifications(@CurrentUser() user: User) {
        const notifications = await this.notificationService.getBuyerNotifications(user.id);
        const unreadCount = await this.notificationService.getBuyerUnreadCount(user.id);
        return {
            success: true,
            notifications,
            unreadCount,
            total: notifications.length,
        };
    }

    @Patch('read-all')
    @ApiOperation({ summary: 'Mark all buyer notifications as read' })
    async markAllAsRead(@CurrentUser() user: User) {
        await this.notificationService.markAllAsRead(user.id);
        return {
            success: true,
            message: 'All notifications marked as read',
        };
    }

    @Patch(':id/read')
    @ApiOperation({ summary: 'Mark buyer notification as read' })
    async markAsRead(@Param('id') id: string) {
        await this.notificationService.markAsRead(id);
        return {
            success: true,
            message: 'Notification marked as read',
        };
    }
}
