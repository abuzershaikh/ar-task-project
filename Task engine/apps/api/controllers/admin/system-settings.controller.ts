import { Controller, Get, Patch, Param, Body, NotFoundException } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { SystemSettingsRepository } from '../../../../shared/database/repositories/system-settings.repository';
import { AuditLogService } from '../../../../shared/services/audit-log.service';
import { Roles } from '../../../../shared/auth/decorators/roles.decorator';
import { CurrentUser } from '../../../../shared/auth/decorators/current-user.decorator';
import { UserRole, User } from '../../../../shared/database/entities/user.entity';

@ApiTags('Admin - System Settings')
@Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
@ApiBearerAuth('bearer')
@Controller('admin/settings')
export class AdminSystemSettingsController {
    constructor(
        private readonly settingsRepo: SystemSettingsRepository,
        private readonly auditLogService: AuditLogService,
    ) { }

    @Get()
    @ApiOperation({ summary: 'Get all database-backed system settings' })
    async getSettings() {
        const settings = await this.settingsRepo.findAll();
        const defaultSettings = [
            { key: 'minimum_withdrawal', value: 50.0, description: 'Minimum withdrawal threshold limit in INR' },
            { key: 'max_concurrent_tasks', value: 5, description: 'Maximum active concurrent tasks allowed per worker' },
            { key: 'task_accept_timeout', value: 1800, description: 'Task acceptance timeout in seconds (30 mins)' },
            { key: 'review_timeout', value: 86400, description: 'Auto-approval review timeout in seconds (24 hours)' },
            { key: 'worker_score_weights', value: { quality: 0.3, completionRate: 0.25, reliability: 0.2, recentPerformance: 0.15, experience: 0.1 } },
            { key: 'rating_weight', value: 0.2, description: 'Rating weight in Matching Brain score calculation' },
        ];

        return {
            success: true,
            settings: settings.length > 0 ? settings : defaultSettings,
        };
    }

    @Get(':key')
    @ApiOperation({ summary: 'Get single system setting by key' })
    async getSettingByKey(@Param('key') key: string) {
        const setting = await this.settingsRepo.findByKey(key);
        if (!setting) {
            return {
                success: true,
                key,
                value: key === 'minimum_withdrawal' ? 50.0 : key === 'max_concurrent_tasks' ? 5 : null,
            };
        }
        return { success: true, setting };
    }

    @Patch(':key')
    @ApiOperation({ summary: 'Update system setting value (Audited)' })
    async updateSetting(
        @Param('key') key: string,
        @Body() body: { value: any; description?: string },
        @CurrentUser() user: User,
    ) {
        if (body.value === undefined) {
            throw new NotFoundException('Value is required to update setting');
        }

        const setting = await this.settingsRepo.set(key, body.value, user ? user.id : 'admin', body.description);

        await this.auditLogService.logAction({
            userId: user ? user.id : 'admin',
            action: 'UPDATE_SYSTEM_SETTING',
            targetType: 'SETTING',
            targetId: key,
            newValue: body.value,
        });

        return {
            success: true,
            setting,
            message: `System setting '${key}' updated successfully`,
        };
    }
}
