import { Controller, Get, Post, Patch, Param, Body, NotFoundException, Logger } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { SystemSettingsRepository } from '../../../../shared/database/repositories/system-settings.repository';
import { AuditLogService } from '../../../../shared/services/audit-log.service';
import { DeadlineMonitorService } from '../../../../shared/engines/reallocation-engine/services/deadline-monitor.service';
import { Roles } from '../../../../shared/auth/decorators/roles.decorator';
import { CurrentUser } from '../../../../shared/auth/decorators/current-user.decorator';
import { UserRole, User } from '../../../../shared/database/entities/user.entity';

@ApiTags('Admin - System Settings')
@Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
@ApiBearerAuth('bearer')
@Controller('admin/settings')
export class AdminSystemSettingsController {
    private readonly logger = new Logger(AdminSystemSettingsController.name);

    constructor(
        private readonly settingsRepo: SystemSettingsRepository,
        private readonly auditLogService: AuditLogService,
        private readonly deadlineMonitor: DeadlineMonitorService,
    ) { }

    @Get('task-expiry')
    @ApiOperation({ summary: 'Get Task Expiry & Auto-Reassignment configuration' })
    async getTaskExpirySettings() {
        const workerTimeoutSetting = await this.settingsRepo.findByKey('worker_execution_timeout_hours');
        const unacceptedExpirySetting = await this.settingsRepo.findByKey('unaccepted_task_expiry_hours');
        const autoReassignSetting = await this.settingsRepo.findByKey('auto_reassign_on_expiry');

        return {
            success: true,
            settings: {
                workerExecutionTimeoutHours: workerTimeoutSetting ? Number(workerTimeoutSetting.value) : 2.0,
                unacceptedTaskExpiryHours: unacceptedExpirySetting ? Number(unacceptedExpirySetting.value) : 24.0,
                autoReassignOnExpiry: autoReassignSetting !== null && autoReassignSetting !== undefined ? Boolean(autoReassignSetting.value) : true,
            },
        };
    }

    @Post('task-expiry')
    @ApiOperation({ summary: 'Update Task Expiry & Auto-Reassignment configuration' })
    async updateTaskExpirySettings(
        @Body() body: {
            workerExecutionTimeoutHours?: number;
            unacceptedTaskExpiryHours?: number;
            autoReassignOnExpiry?: boolean;
        },
        @CurrentUser() user: User,
    ) {
        const userId = user ? user.id : 'admin';

        if (body.workerExecutionTimeoutHours !== undefined) {
            await this.settingsRepo.set(
                'worker_execution_timeout_hours',
                Number(body.workerExecutionTimeoutHours),
                userId,
                'Worker execution deadline in hours after accepting a task',
            );
        }

        if (body.unacceptedTaskExpiryHours !== undefined) {
            await this.settingsRepo.set(
                'unaccepted_task_expiry_hours',
                Number(body.unacceptedTaskExpiryHours),
                userId,
                'Unaccepted pool task expiration time in hours',
            );
        }

        if (body.autoReassignOnExpiry !== undefined) {
            await this.settingsRepo.set(
                'auto_reassign_on_expiry',
                Boolean(body.autoReassignOnExpiry),
                userId,
                'Automatically release and reassign expired tasks to other workers',
            );
        }

        await this.auditLogService.logAction({
            userId,
            action: 'UPDATE_TASK_EXPIRY_SETTINGS',
            targetType: 'SYSTEM_SETTINGS',
            targetId: 'TASK_EXPIRY',
            newValue: body,
        });

        return {
            success: true,
            message: 'Task Expiry & Timeout configurations saved successfully',
            settings: {
                workerExecutionTimeoutHours: body.workerExecutionTimeoutHours ?? 2.0,
                unacceptedTaskExpiryHours: body.unacceptedTaskExpiryHours ?? 24.0,
                autoReassignOnExpiry: body.autoReassignOnExpiry ?? true,
            },
        };
    }

    @Post('task-expiry/trigger')
    @ApiOperation({ summary: 'Trigger manual task deadline evaluation & reallocation cycle' })
    async triggerDeadlineEvaluation(@CurrentUser() user: User) {
        this.logger.log(`Manual deadline evaluation triggered by user ${user?.id || 'admin'}`);
        const result = await this.deadlineMonitor.monitorDeadlines();
        return {
            success: true,
            message: 'Deadline monitor cycle executed successfully',
            result,
        };
    }

    @Get()
    @ApiOperation({ summary: 'Get all database-backed system settings' })
    async getSettings() {
        const settings = await this.settingsRepo.findAll();
        const defaultSettings = [
            { key: 'minimum_withdrawal', value: 50.0, description: 'Minimum withdrawal threshold limit in INR' },
            { key: 'max_concurrent_tasks', value: 5, description: 'Maximum active concurrent tasks allowed per worker' },
            { key: 'worker_execution_timeout_hours', value: 2.0, description: 'Worker execution timeout in hours' },
            { key: 'unaccepted_task_expiry_hours', value: 24.0, description: 'Unaccepted task pool expiry in hours' },
            { key: 'auto_reassign_on_expiry', value: true, description: 'Auto-reassign expired tasks' },
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
