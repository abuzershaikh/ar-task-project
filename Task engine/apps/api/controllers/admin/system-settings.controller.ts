import { Controller, Get, Post, Patch, Delete, Param, Body, NotFoundException, Logger } from '@nestjs/common';
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

    @Get('app-updates')
    @ApiOperation({ summary: 'Get App Version Update List and Release configuration' })
    async getAppUpdateSettings() {
        const updateVersionsSetting = await this.settingsRepo.findByKey('worker_app_update_versions');
        const latestVersionSetting = await this.settingsRepo.findByKey('latest_worker_app_version');
        const apkUrlSetting = await this.settingsRepo.findByKey('latest_worker_apk_url');
        const updateMsgSetting = await this.settingsRepo.findByKey('force_update_message');
        const releaseNotesSetting = await this.settingsRepo.findByKey('worker_app_release_notes');

        let updateList: string[] = [];
        try {
            if (updateVersionsSetting?.value) {
                if (Array.isArray(updateVersionsSetting.value)) {
                    updateList = updateVersionsSetting.value.map((v: any) => v.toString().trim());
                } else if (typeof updateVersionsSetting.value === 'string') {
                    updateList = JSON.parse(updateVersionsSetting.value).map((v: any) => v.toString().trim());
                }
            }
        } catch (_) {
            updateList = [];
        }

        return {
            success: true,
            settings: {
                updateList,
                latestVersion: (latestVersionSetting?.value || '1.0.1').toString(),
                apkDownloadUrl: (apkUrlSetting?.value || 'https://raw.githubusercontent.com/abuzershaikh/ar-task-project/main/Worker_App_Release.apk').toString(),
                updateMessage: (updateMsgSetting?.value || 'A new version of Task Reward Worker is available. Please update your app to continue.').toString(),
                releaseNotes: (releaseNotesSetting?.value || '• New task execution engine\n• Real-time notification deep linking\n• Improved stability and security').toString(),
            },
        };
    }

    @Post('app-updates')
    @ApiOperation({ summary: 'Update App Version Update List and Release configuration' })
    async saveAppUpdateSettings(
        @Body() body: {
            updateList?: string[];
            latestVersion?: string;
            apkDownloadUrl?: string;
            updateMessage?: string;
            releaseNotes?: string;
        },
        @CurrentUser() user: User,
    ) {
        const userId = user ? user.id : 'admin';

        if (body.updateList !== undefined) {
            await this.settingsRepo.set(
                'worker_app_update_versions',
                body.updateList,
                userId,
                'List of app versions that must update',
            );
        }

        if (body.latestVersion !== undefined) {
            await this.settingsRepo.set(
                'latest_worker_app_version',
                body.latestVersion.trim(),
                userId,
                'Latest released version name',
            );
        }

        if (body.apkDownloadUrl !== undefined) {
            await this.settingsRepo.set(
                'latest_worker_apk_url',
                body.apkDownloadUrl.trim(),
                userId,
                'Direct APK download URL for updates',
            );
        }

        if (body.updateMessage !== undefined) {
            await this.settingsRepo.set(
                'force_update_message',
                body.updateMessage.trim(),
                userId,
                'Forced update prompt message',
            );
        }

        if (body.releaseNotes !== undefined) {
            await this.settingsRepo.set(
                'worker_app_release_notes',
                body.releaseNotes.trim(),
                userId,
                'Release notes and changelog',
            );
        }

        await this.auditLogService.logAction({
            userId,
            action: 'UPDATE_APP_UPDATE_SETTINGS',
            targetType: 'SYSTEM_SETTINGS',
            targetId: 'APP_UPDATES',
            newValue: body,
        });

        return {
            success: true,
            message: 'App version update settings saved successfully',
        };
    }

    @Post('app-updates/add-version')
    @ApiOperation({ summary: 'Add a single version string to the update list' })
    async addVersionToUpdateList(
        @Body() body: { version: string },
        @CurrentUser() user: User,
    ) {
        const userId = user ? user.id : 'admin';
        const vToAdd = (body.version || '').trim();
        if (!vToAdd) {
            throw new NotFoundException('Version string is required');
        }

        const updateVersionsSetting = await this.settingsRepo.findByKey('worker_app_update_versions');
        let currentList: string[] = [];
        try {
            if (updateVersionsSetting?.value) {
                if (Array.isArray(updateVersionsSetting.value)) {
                    currentList = updateVersionsSetting.value.map((v: any) => v.toString().trim());
                } else if (typeof updateVersionsSetting.value === 'string') {
                    currentList = JSON.parse(updateVersionsSetting.value).map((v: any) => v.toString().trim());
                }
            }
        } catch (_) {}

        if (!currentList.includes(vToAdd)) {
            currentList.push(vToAdd);
            await this.settingsRepo.set('worker_app_update_versions', currentList, userId, 'List of app versions that must update');
        }

        return {
            success: true,
            message: `Version '${vToAdd}' added to update list`,
            updateList: currentList,
        };
    }

    @Delete('app-updates/remove-version/:version')
    @ApiOperation({ summary: 'Remove a version string from the update list' })
    async removeVersionFromUpdateList(
        @Param('version') version: string,
        @CurrentUser() user: User,
    ) {
        const userId = user ? user.id : 'admin';
        const vToRemove = (version || '').trim();

        const updateVersionsSetting = await this.settingsRepo.findByKey('worker_app_update_versions');
        let currentList: string[] = [];
        try {
            if (updateVersionsSetting?.value) {
                if (Array.isArray(updateVersionsSetting.value)) {
                    currentList = updateVersionsSetting.value.map((v: any) => v.toString().trim());
                } else if (typeof updateVersionsSetting.value === 'string') {
                    currentList = JSON.parse(updateVersionsSetting.value).map((v: any) => v.toString().trim());
                }
            }
        } catch (_) {}

        currentList = currentList.filter((v) => v !== vToRemove && v !== `v${vToRemove}` && `v${v}` !== vToRemove);
        await this.settingsRepo.set('worker_app_update_versions', currentList, userId, 'List of app versions that must update');

        return {
            success: true,
            message: `Version '${vToRemove}' removed from update list`,
            updateList: currentList,
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
