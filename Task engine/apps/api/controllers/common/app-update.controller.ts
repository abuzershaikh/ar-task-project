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
    @ApiOperation({ summary: 'Check if current app version requires an update' })
    async checkUpdate(
        @Query('version') version?: string,
        @Query('app') app: string = 'worker',
    ) {
        const clientVersion = (version || '1.0.0').trim().toLowerCase().replace(/^v/, '');

        // Fetch settings from system_settings table
        const updateVersionsSetting = await this.settingsRepo.findByKey('worker_app_update_versions');
        const latestVersionSetting = await this.settingsRepo.findByKey('latest_worker_app_version');
        const apkUrlSetting = await this.settingsRepo.findByKey('latest_worker_apk_url');
        const updateMsgSetting = await this.settingsRepo.findByKey('force_update_message');
        const releaseNotesSetting = await this.settingsRepo.findByKey('worker_app_release_notes');

        // Parse versions list from DB
        let updateList: string[] = [];
        try {
            if (updateVersionsSetting?.value) {
                if (Array.isArray(updateVersionsSetting.value)) {
                    updateList = updateVersionsSetting.value.map((v: any) => v.toString().trim().toLowerCase().replace(/^v/, ''));
                } else if (typeof updateVersionsSetting.value === 'string') {
                    updateList = JSON.parse(updateVersionsSetting.value).map((v: any) => v.toString().trim().toLowerCase().replace(/^v/, ''));
                }
            }
        } catch (_) {
            updateList = [];
        }

        const latestVersion = (latestVersionSetting?.value || '1.0.1').toString().trim();
        const downloadUrl = (apkUrlSetting?.value || 'https://raw.githubusercontent.com/abuzershaikh/ar-task-project/main/Worker_App_Release.apk').toString().trim();
        const message = (updateMsgSetting?.value || 'A new version of Task Reward Worker is available. Please update your app to continue.').toString().trim();
        const releaseNotes = (releaseNotesSetting?.value || '• New task execution engine\n• Real-time notification deep linking\n• Improved stability and security').toString().trim();

        // Match client version against update list
        const isMatchedInUpdateList = updateList.some((v) => v === clientVersion || v === clientVersion.replace(/\.0$/, ''));

        this.logger.log(`App update check: Client='${clientVersion}', UpdateList=[${updateList.join(', ')}], RequiresUpdate=${isMatchedInUpdateList}`);

        return {
            success: true,
            updateRequired: isMatchedInUpdateList,
            clientVersion: version || '1.0.0',
            latestVersion,
            downloadUrl,
            message,
            releaseNotes,
            updateList,
        };
    }
}
