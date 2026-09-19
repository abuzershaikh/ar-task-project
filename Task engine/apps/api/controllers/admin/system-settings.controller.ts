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

        const parseBool = (val: any, defaultVal = true): boolean => {
            if (val === null || val === undefined) return defaultVal;
            if (typeof val === 'boolean') return val;
            const s = String(val).trim().toLowerCase();
            if (s === 'false' || s === '0' || s === 'no') return false;
            if (s === 'true' || s === '1' || s === 'yes') return true;
            return defaultVal;
        };

        return {
            success: true,
            settings: {
                workerExecutionTimeoutHours: workerTimeoutSetting ? Number(workerTimeoutSetting.value) : 2.0,
                unacceptedTaskExpiryHours: unacceptedExpirySetting ? Number(unacceptedExpirySetting.value) : 24.0,
                autoReassignOnExpiry: parseBool(autoReassignSetting?.value, true),
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
    @ApiOperation({ summary: 'Get current App Updates & Version Registry settings' })
    async getAppUpdateSettings() {
        const updateVersionsSetting = await this.settingsRepo.findByKey('worker_app_update_versions');
        const versionRegistrySetting = await this.settingsRepo.findByKey('worker_app_version_registry');
        const latestVersionSetting = await this.settingsRepo.findByKey('latest_worker_app_version');
        const latestCodeSetting = await this.settingsRepo.findByKey('latest_worker_version_code');
        const apkUrlSetting = await this.settingsRepo.findByKey('latest_worker_apk_url');
        const updateMsgSetting = await this.settingsRepo.findByKey('force_update_message');
        const releaseNotesSetting = await this.settingsRepo.findByKey('worker_app_release_notes');

        const rawApk = (apkUrlSetting?.value || '').toString();
        const apkDownloadUrl = (rawApk.includes('github.com') || rawApk.includes('raw.githubusercontent.com')) ? '' : rawApk;
        const latestVersion = (latestVersionSetting?.value || '1.0.5').toString();
        const latestVersionCode = (latestCodeSetting?.value || '5').toString();
        const updateMessage = (updateMsgSetting?.value || 'A new version of Task Reward Worker is available. Please update your app to continue.').toString();
        const releaseNotes = (releaseNotesSetting?.value || '• New task execution engine\n• Real-time notification deep linking\n• Improved stability and security').toString();

        let legacyUpdateList: string[] = [];
        try {
            if (updateVersionsSetting?.value) {
                if (Array.isArray(updateVersionsSetting.value)) {
                    legacyUpdateList = updateVersionsSetting.value.map((v: any) => v.toString().trim());
                } else if (typeof updateVersionsSetting.value === 'string') {
                    legacyUpdateList = JSON.parse(updateVersionsSetting.value).map((v: any) => v.toString().trim());
                }
            }
        } catch (_) {
            legacyUpdateList = [];
        }

        let versionList: any[] = [];
        try {
            if (versionRegistrySetting?.value) {
                if (Array.isArray(versionRegistrySetting.value)) {
                    versionList = versionRegistrySetting.value;
                } else if (typeof versionRegistrySetting.value === 'string') {
                    versionList = JSON.parse(versionRegistrySetting.value);
                }
            }
        } catch (_) {
            versionList = [];
        }

        // Auto-seed or migrate if registry is empty
        if (versionList.length === 0) {
            if (legacyUpdateList.length > 0) {
                versionList = legacyUpdateList.map((v, idx) => ({
                    id: `v-${idx + 1}`,
                    versionName: v,
                    versionCode: v.replace(/\D/g, '') || `${idx + 1}`,
                    status: 'disabled',
                    updateUrl: apkDownloadUrl,
                    message: updateMessage,
                    updatedAt: new Date().toISOString(),
                }));
            } else {
                versionList = [
                    {
                        id: 'v-1',
                        versionName: '1.0.0',
                        versionCode: '1',
                        status: 'disabled',
                        updateUrl: apkDownloadUrl,
                        message: 'Initial release is deprecated. Please update to latest version.',
                        updatedAt: new Date().toISOString(),
                    },
                    {
                        id: 'v-2',
                        versionName: '1.0.4',
                        versionCode: '4',
                        status: 'disabled',
                        updateUrl: apkDownloadUrl,
                        message: 'Older build is disabled. Please update to latest version.',
                        updatedAt: new Date().toISOString(),
                    },
                    {
                        id: 'v-3',
                        versionName: latestVersion,
                        versionCode: latestVersionCode,
                        status: 'active',
                        updateUrl: apkDownloadUrl,
                        message: 'Current latest production release',
                        updatedAt: new Date().toISOString(),
                    },
                ];
            }
        }

        versionList = versionList.map((v: any) => {
            if (v && v.updateUrl && (v.updateUrl.includes('github.com') || v.updateUrl.includes('raw.githubusercontent.com'))) {
                return { ...v, updateUrl: '' };
            }
            return v;
        });

        return {
            success: true,
            settings: {
                versionList,
                updateList: versionList.filter((v) => v.status === 'disabled').map((v) => v.versionName),
                latestVersion,
                latestVersionCode,
                apkDownloadUrl,
                updateMessage,
                releaseNotes,
            },
        };
    }

    @Post('app-updates')
    @ApiOperation({ summary: 'Update App Version Registry and Release configuration' })
    async saveAppUpdateSettings(
        @Body() body: {
            versionList?: any[];
            updateList?: string[];
            latestVersion?: string;
            latestVersionCode?: string;
            apkDownloadUrl?: string;
            updateMessage?: string;
            releaseNotes?: string;
        },
        @CurrentUser() user: User,
    ) {
        const userId = user ? user.id : 'admin';

        if (body.versionList !== undefined) {
            await this.settingsRepo.set(
                'worker_app_version_registry',
                body.versionList,
                userId,
                'Full registry of worker app version codes and status',
            );
            // Also sync legacy updateList
            const disabledNames = body.versionList
                .filter((v) => v.status === 'disabled')
                .map((v) => (v.versionName || '').toString().trim())
                .filter(Boolean);
            await this.settingsRepo.set(
                'worker_app_update_versions',
                disabledNames,
                userId,
                'List of app versions that must update',
            );
        } else if (body.updateList !== undefined) {
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

        if (body.latestVersionCode !== undefined) {
            await this.settingsRepo.set(
                'latest_worker_version_code',
                body.latestVersionCode.trim(),
                userId,
                'Latest released version code',
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
    @ApiOperation({ summary: 'Add a new version code or release to the registry' })
    async addVersionToUpdateList(
        @Body() body: {
            version?: string;
            versionName?: string;
            versionCode?: string;
            status?: 'active' | 'disabled';
            updateUrl?: string;
            message?: string;
        },
        @CurrentUser() user: User,
    ) {
        const userId = user ? user.id : 'admin';
        const vName = (body.versionName || body.version || '').trim();
        const vCode = (body.versionCode || vName.replace(/\D/g, '') || '1').trim();
        const status = body.status === 'active' ? 'active' : 'disabled'; // default disabled

        if (!vName && !vCode) {
            throw new NotFoundException('Version name or version code is required');
        }

        const apkUrlSetting = await this.settingsRepo.findByKey('latest_worker_apk_url');
        const rawApk = (apkUrlSetting?.value || '').toString();
        const defaultApk = (rawApk.includes('github.com') || rawApk.includes('raw.githubusercontent.com')) ? '' : rawApk;
        const updateUrl = (body.updateUrl || defaultApk).trim();

        // Load existing registry
        const versionRegistrySetting = await this.settingsRepo.findByKey('worker_app_version_registry');
        let versionList: any[] = [];
        try {
            if (versionRegistrySetting?.value) {
                if (Array.isArray(versionRegistrySetting.value)) {
                    versionList = [...versionRegistrySetting.value];
                } else if (typeof versionRegistrySetting.value === 'string') {
                    versionList = JSON.parse(versionRegistrySetting.value);
                }
            }
        } catch (_) {
            versionList = [];
        }

        // Check if exists, update or add
        const existingIdx = versionList.findIndex(
            (v) => (v.versionName && v.versionName.toLowerCase() === vName.toLowerCase()) ||
                   (v.versionCode && v.versionCode.toString() === vCode.toString())
        );

        const newRecord = {
            id: existingIdx >= 0 ? versionList[existingIdx].id : `v-${Date.now()}`,
            versionName: vName,
            versionCode: vCode,
            status,
            updateUrl,
            message: body.message || 'Please update your app to continue.',
            updatedAt: new Date().toISOString(),
        };

        if (existingIdx >= 0) {
            versionList[existingIdx] = newRecord;
        } else {
            versionList.push(newRecord);
        }

        await this.settingsRepo.set('worker_app_version_registry', versionList, userId, 'Full registry of worker app version codes');

        // Sync legacy updateList
        const disabledNames = versionList
            .filter((v) => v.status === 'disabled')
            .map((v) => (v.versionName || '').toString().trim())
            .filter(Boolean);
        await this.settingsRepo.set('worker_app_update_versions', disabledNames, userId, 'List of app versions that must update');

        return {
            success: true,
            message: `Version '${vName}' (Code: ${vCode}) added as ${status.toUpperCase()}`,
            versionRecord: newRecord,
            versionList,
        };
    }

    @Post('app-updates/toggle-status')
    @ApiOperation({ summary: 'Toggle status of a version (Disable / Enable) and optionally set update link' })
    async toggleVersionStatus(
        @Body() body: {
            id?: string;
            versionName?: string;
            versionCode?: string;
            status: 'active' | 'disabled';
            updateUrl?: string;
            message?: string;
        },
        @CurrentUser() user: User,
    ) {
        const userId = user ? user.id : 'admin';
        const targetId = body.id;
        const targetName = (body.versionName || '').trim().toLowerCase();
        const targetCode = (body.versionCode || '').trim();

        const versionRegistrySetting = await this.settingsRepo.findByKey('worker_app_version_registry');
        let versionList: any[] = [];
        try {
            if (versionRegistrySetting?.value) {
                if (Array.isArray(versionRegistrySetting.value)) {
                    versionList = [...versionRegistrySetting.value];
                } else if (typeof versionRegistrySetting.value === 'string') {
                    versionList = JSON.parse(versionRegistrySetting.value);
                }
            }
        } catch (_) {
            versionList = [];
        }

        let found = false;
        for (const v of versionList) {
            if (
                (targetId && v.id === targetId) ||
                (targetName && v.versionName && v.versionName.toLowerCase() === targetName) ||
                (targetCode && v.versionCode && v.versionCode.toString() === targetCode)
            ) {
                v.status = body.status;
                if (body.updateUrl) {
                    v.updateUrl = body.updateUrl.trim();
                }
                if (body.message) {
                    v.message = body.message.trim();
                }
                v.updatedAt = new Date().toISOString();
                found = true;
                break;
            }
        }

        if (!found) {
            // Create a new record if not found
            versionList.push({
                id: targetId || `v-${Date.now()}`,
                versionName: body.versionName || targetCode,
                versionCode: targetCode || '1',
                status: body.status,
                updateUrl: body.updateUrl || '',
                message: body.message || 'Please update your app to continue.',
                updatedAt: new Date().toISOString(),
            });
        }

        await this.settingsRepo.set('worker_app_version_registry', versionList, userId, 'Full registry of worker app version codes');

        // Sync legacy updateList
        const disabledNames = versionList
            .filter((v) => v.status === 'disabled')
            .map((v) => (v.versionName || '').toString().trim())
            .filter(Boolean);
        await this.settingsRepo.set('worker_app_update_versions', disabledNames, userId, 'List of app versions that must update');

        return {
            success: true,
            message: `Version status updated to ${body.status.toUpperCase()}`,
            versionList,
        };
    }

    @Delete('app-updates/remove-version/:version')
    @ApiOperation({ summary: 'Remove a version string or code from the registry' })
    async removeVersionFromUpdateList(
        @Param('version') version: string,
        @CurrentUser() user: User,
    ) {
        const userId = user ? user.id : 'admin';
        const vToRemove = (version || '').trim().toLowerCase();

        // 1. Remove from version registry
        const versionRegistrySetting = await this.settingsRepo.findByKey('worker_app_version_registry');
        let versionList: any[] = [];
        try {
            if (versionRegistrySetting?.value) {
                if (Array.isArray(versionRegistrySetting.value)) {
                    versionList = [...versionRegistrySetting.value];
                } else if (typeof versionRegistrySetting.value === 'string') {
                    versionList = JSON.parse(versionRegistrySetting.value);
                }
            }
        } catch (_) {}

        versionList = versionList.filter((v) => {
            const matchName = v.versionName && v.versionName.toLowerCase() === vToRemove;
            const matchCode = v.versionCode && v.versionCode.toString() === vToRemove;
            const matchId = v.id && v.id === version;
            return !matchName && !matchCode && !matchId;
        });

        await this.settingsRepo.set('worker_app_version_registry', versionList, userId, 'Full registry of worker app version codes');

        // 2. Remove from legacy list
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

        currentList = currentList.filter((v) => v.toLowerCase() !== vToRemove && `v${v.toLowerCase()}` !== vToRemove);
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
            { key: 'app_install_min_retention_hours', value: 24.0, description: 'Default minimum hours worker must keep installed apps on phone' },
            { key: 'app_install_allow_negative_balance', value: true, description: 'Allow negative wallet balance if worker withdrew earnings before early uninstall' },
            { key: 'app_install_strict_penalty', value: true, description: 'Strictly penalize and deduct task earnings upon early uninstall detection' },
            { key: 'worker_score_weights', value: { quality: 0.3, completionRate: 0.25, reliability: 0.2, recentPerformance: 0.15, experience: 0.1 } },
            { key: 'rating_weight', value: 0.2, description: 'Rating weight in Matching Brain score calculation' },
        ];

        return {
            success: true,
            settings: settings.length > 0 ? settings : defaultSettings,
        };
    }

    @Get('app-retention')
    @ApiOperation({ summary: 'Get App Install Retention & Penalty Settings' })
    async getAppRetentionSettings() {
        const retentionHoursSetting = await this.settingsRepo.findByKey('app_install_min_retention_hours');
        const allowNegativeSetting = await this.settingsRepo.findByKey('app_install_allow_negative_balance');
        const strictPenaltySetting = await this.settingsRepo.findByKey('app_install_strict_penalty');

        const parseBool = (val: any, defaultVal = true): boolean => {
            if (val === null || val === undefined) return defaultVal;
            if (typeof val === 'boolean') return val;
            const s = String(val).trim().toLowerCase();
            if (s === 'false' || s === '0' || s === 'no') return false;
            if (s === 'true' || s === '1' || s === 'yes') return true;
            return defaultVal;
        };

        return {
            success: true,
            settings: {
                minRetentionHours: retentionHoursSetting ? Number(retentionHoursSetting.value) : 24.0,
                allowNegativeBalance: parseBool(allowNegativeSetting?.value, true),
                strictPenalty: parseBool(strictPenaltySetting?.value, true),
            },
        };
    }

    @Post('app-retention')
    @ApiOperation({ summary: 'Update App Install Retention & Penalty Settings' })
    async saveAppRetentionSettings(
        @Body() body: {
            minRetentionHours?: number;
            allowNegativeBalance?: boolean;
            strictPenalty?: boolean;
        },
        @CurrentUser() user: User,
    ) {
        const userId = user ? user.id : 'admin';

        if (body.minRetentionHours !== undefined) {
            await this.settingsRepo.set(
                'app_install_min_retention_hours',
                Number(body.minRetentionHours),
                userId,
                'Minimum hours worker must keep app installed on their phone',
            );
        }

        if (body.allowNegativeBalance !== undefined) {
            await this.settingsRepo.set(
                'app_install_allow_negative_balance',
                Boolean(body.allowNegativeBalance),
                userId,
                'Allow worker wallet balance to go negative if already withdrawn upon early uninstall',
            );
        }

        if (body.strictPenalty !== undefined) {
            await this.settingsRepo.set(
                'app_install_strict_penalty',
                Boolean(body.strictPenalty),
                userId,
                'Strictly penalize and deduct task earnings upon detecting early uninstall',
            );
        }

        await this.auditLogService.logAction({
            userId,
            action: 'UPDATE_APP_RETENTION_SETTINGS',
            targetType: 'SYSTEM_SETTINGS',
            targetId: 'APP_RETENTION',
            newValue: body,
        });

        return {
            success: true,
            message: 'App Install Retention & Penalty settings updated successfully',
            settings: {
                minRetentionHours: body.minRetentionHours ?? 24.0,
                allowNegativeBalance: body.allowNegativeBalance ?? true,
                strictPenalty: body.strictPenalty ?? true,
            },
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
