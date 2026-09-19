import { Controller, Get, Query, Logger } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { SystemSettingsRepository } from '../../../../shared/database/repositories/system-settings.repository';
import { Public } from '../../../../shared/auth/decorators/public.decorator';

@ApiTags('App Updates & Versioning')
@Controller('app')
export class AppUpdateController {
    private readonly logger = new Logger(AppUpdateController.name);

    constructor(private readonly settingsRepo: SystemSettingsRepository) { }

    @Public()
    @Get('check-update')
    @ApiOperation({ summary: 'Check if current app version or version code requires an update' })
    async checkUpdate(
        @Query('version') version?: string,
        @Query('versionCode') versionCode?: string,
        @Query('app') app: string = 'worker',
    ) {
        const rawVersion = (version || '1.0.0').trim();
        // Handle cases like "1.0.4+4" or "1.0.4 4"
        const parts = rawVersion.split(/[+ ]/);
        const clientVersion = parts[0].trim().toLowerCase().replace(/^v/, '');
        const clientVersionCode = (versionCode || parts[1] || '').trim();

        // Fetch settings from system_settings table
        const versionRegistrySetting = await this.settingsRepo.findByKey('worker_app_version_registry');
        const updateVersionsSetting = await this.settingsRepo.findByKey('worker_app_update_versions');
        const latestVersionSetting = await this.settingsRepo.findByKey('latest_worker_app_version');
        const latestCodeSetting = await this.settingsRepo.findByKey('latest_worker_version_code');
        const apkUrlSetting = await this.settingsRepo.findByKey('latest_worker_apk_url');
        const updateMsgSetting = await this.settingsRepo.findByKey('force_update_message');
        const releaseNotesSetting = await this.settingsRepo.findByKey('worker_app_release_notes');

        // Parse versions registry from DB
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

        // Parse legacy updateList from DB
        let legacyUpdateList: string[] = [];
        try {
            if (updateVersionsSetting?.value) {
                if (Array.isArray(updateVersionsSetting.value)) {
                    legacyUpdateList = updateVersionsSetting.value.map((v: any) => v.toString().trim().toLowerCase().replace(/^v/, ''));
                } else if (typeof updateVersionsSetting.value === 'string') {
                    legacyUpdateList = JSON.parse(updateVersionsSetting.value).map((v: any) => v.toString().trim().toLowerCase().replace(/^v/, ''));
                }
            }
        } catch (_) {
            legacyUpdateList = [];
        }

        const latestVersion = (latestVersionSetting?.value || '1.0.5').toString().trim();
        const latestVersionCode = (latestCodeSetting?.value || '5').toString().trim();
        const rawDownloadUrl = (apkUrlSetting?.value || '').toString().trim();
        const globalDownloadUrl = (rawDownloadUrl.includes('github.com') || rawDownloadUrl.includes('raw.githubusercontent.com')) ? '' : rawDownloadUrl;
        const globalMessage = (updateMsgSetting?.value || 'A new version of Task Reward Worker is available. Please update your app to continue.').toString().trim();
        const releaseNotes = (releaseNotesSetting?.value || '• New task execution engine\n• Real-time notification deep linking\n• Improved stability and security').toString().trim();

        const cleanClient = clientVersion.split('+')[0];
        const cleanLatest = latestVersion.toLowerCase().replace(/^v/, '').split('+')[0];

        // Semantic version compare helper: returns true if v1 < v2
        const isOlder = (v1: string, v2: string): boolean => {
            const p1 = v1.split('.').map(n => parseInt(n, 10) || 0);
            const p2 = v2.split('.').map(n => parseInt(n, 10) || 0);
            for (let i = 0; i < Math.max(p1.length, p2.length); i++) {
                const num1 = p1[i] || 0;
                const num2 = p2[i] || 0;
                if (num1 < num2) return true;
                if (num1 > num2) return false;
            }
            return false;
        };

        let updateRequired = false;
        let resolvedDownloadUrl = globalDownloadUrl;
        let resolvedMessage = globalMessage;
        let matchReason = 'none';

        // 1. Check version registry first
        if (versionList.length > 0) {
            const matchedRecord = versionList.find((item) => {
                const itemVName = (item.versionName || '').trim().toLowerCase().replace(/^v/, '').split('+')[0];
                const itemVCode = (item.versionCode || '').toString().trim();

                const nameMatch = itemVName && (itemVName === cleanClient || itemVName === cleanClient.replace(/\.0$/, ''));
                const codeMatch = clientVersionCode && itemVCode && (itemVCode === clientVersionCode);

                return nameMatch || codeMatch;
            });

            if (matchedRecord) {
                if (matchedRecord.status === 'disabled') {
                    updateRequired = true;
                    if (matchedRecord.updateUrl && matchedRecord.updateUrl.trim().length > 0) {
                        const recUrl = matchedRecord.updateUrl.trim();
                        if (!recUrl.includes('github.com') && !recUrl.includes('raw.githubusercontent.com')) {
                            resolvedDownloadUrl = recUrl;
                        }
                    }
                    if (matchedRecord.message && matchedRecord.message.trim().length > 0) {
                        resolvedMessage = matchedRecord.message.trim();
                    }
                    matchReason = `registry_disabled (versionName='${matchedRecord.versionName}', versionCode='${matchedRecord.versionCode}')`;
                } else if (matchedRecord.status === 'active') {
                    updateRequired = false;
                    matchReason = `registry_active (versionName='${matchedRecord.versionName}', versionCode='${matchedRecord.versionCode}')`;
                }
            }
        }

        // 2. If no decisive registry match, check legacy update list and wildcards
        if (matchReason === 'none') {
            const isMatchedInLegacyList = legacyUpdateList.some((v) => {
                const cleanV = v.trim().toLowerCase().replace(/^v/, '').split('+')[0];
                if (cleanV === '*' || cleanV === 'all' || cleanV === 'all_older') {
                    return cleanClient !== cleanLatest && isOlder(cleanClient, cleanLatest);
                }
                return cleanV === cleanClient ||
                       cleanV === cleanClient.replace(/\.0$/, '') ||
                       cleanClient === cleanV.replace(/\.0$/, '') ||
                       (clientVersionCode && cleanV === clientVersionCode);
            });

            if (isMatchedInLegacyList) {
                updateRequired = true;
                matchReason = 'legacy_update_list';
            }
        }

        this.logger.log(`App update check: Client='${clientVersion}' (code='${clientVersionCode}'), Latest='${latestVersion}' (code='${latestVersionCode}'), RequiresUpdate=${updateRequired}, Reason=${matchReason}`);

        return {
            success: true,
            updateRequired,
            clientVersion: version || '1.0.0',
            clientVersionCode,
            latestVersion,
            latestVersionCode,
            downloadUrl: resolvedDownloadUrl,
            message: resolvedMessage,
            releaseNotes,
        };
    }
}
