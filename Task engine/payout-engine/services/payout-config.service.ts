import { Injectable, OnModuleInit, Logger } from '@nestjs/common';
import { SystemSettingsRepository } from '../../shared/database/repositories/system-settings.repository';

@Injectable()
export class PayoutConfigService implements OnModuleInit {
    private readonly logger = new Logger(PayoutConfigService.name);
    private globalMinWithdrawalLimit = 100.0;

    constructor(private readonly settingsRepo: SystemSettingsRepository) { }

    async onModuleInit() {
        await this.loadFromDb();
    }

    async loadFromDb(): Promise<void> {
        try {
            const setting = await this.settingsRepo.findByKey('minimum_withdrawal');
            if (setting && setting.value !== undefined && setting.value !== null) {
                const val = Number(setting.value);
                if (!isNaN(val) && val >= 0) {
                    this.globalMinWithdrawalLimit = val;
                    this.logger.log(`Initialized global minimum_withdrawal from DB: ₹${val}`);
                    return;
                }
            }

            // Seed default into system_settings if not present
            await this.settingsRepo.set(
                'minimum_withdrawal',
                this.globalMinWithdrawalLimit,
                'system',
                'Minimum worker withdrawal threshold in INR',
            );
        } catch (e: any) {
            this.logger.warn(`Could not load minimum_withdrawal from DB: ${e.message}`);
        }
    }

    getGlobalMinWithdrawalLimit(): number {
        return this.globalMinWithdrawalLimit;
    }

    async setGlobalMinWithdrawalLimit(limit: number, updatedBy = 'admin'): Promise<void> {
        if (limit >= 0) {
            this.globalMinWithdrawalLimit = limit;
            try {
                await this.settingsRepo.set(
                    'minimum_withdrawal',
                    limit,
                    updatedBy,
                    'Minimum worker withdrawal threshold in INR',
                );
                this.logger.log(`Updated and persisted minimum_withdrawal in DB: ₹${limit} by ${updatedBy}`);
            } catch (e: any) {
                this.logger.error(`Failed to persist minimum_withdrawal in DB: ${e.message}`);
            }
        }
    }
}
