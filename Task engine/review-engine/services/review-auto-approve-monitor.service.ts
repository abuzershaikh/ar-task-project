import { Injectable, Logger, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { SubmissionRepository } from '../../shared/database/repositories/submission.repository';
import { SystemSettingsRepository } from '../../shared/database/repositories/system-settings.repository';
import { ReviewEngineService } from '../review.service';

@Injectable()
export class ReviewAutoApproveMonitorService implements OnModuleInit, OnModuleDestroy {
    private readonly logger = new Logger(ReviewAutoApproveMonitorService.name);
    private monitorInterval: NodeJS.Timeout | null = null;
    private isRunningCycle = false;

    constructor(
        private readonly submissionRepo: SubmissionRepository,
        private readonly settingsRepo: SystemSettingsRepository,
        private readonly reviewEngine: ReviewEngineService,
    ) { }

    onModuleInit() {
        this.logger.log('🕒 Initializing automated Review Auto-Approve background monitor (interval: 60s)...');
        // Initial delayed execution (20s after startup)
        setTimeout(() => {
            this.evaluatePendingReviews().catch((err) =>
                this.logger.warn(`Initial review auto-approve check warning: ${err.message}`),
            );
        }, 20000);

        // Continuous 60-second background cycle
        this.monitorInterval = setInterval(async () => {
            if (this.isRunningCycle) return;
            try {
                this.isRunningCycle = true;
                await this.evaluatePendingReviews();
            } catch (err) {
                this.logger.error(`Automated review auto-approve cycle error: ${err.message}`);
            } finally {
                this.isRunningCycle = false;
            }
        }, 60000);
    }

    onModuleDestroy() {
        if (this.monitorInterval) {
            clearInterval(this.monitorInterval);
            this.monitorInterval = null;
        }
    }

    async getAutoApproveSettings() {
        try {
            const hoursSetting = await this.settingsRepo.findByKey('review_auto_approve_hours');
            const enabledSetting = await this.settingsRepo.findByKey('review_auto_approve_enabled');

            const parseBool = (val: any, defaultVal = true): boolean => {
                if (val === null || val === undefined) return defaultVal;
                if (typeof val === 'boolean') return val;
                const s = String(val).trim().toLowerCase();
                if (s === 'false' || s === '0' || s === 'no') return false;
                if (s === 'true' || s === '1' || s === 'yes') return true;
                return defaultVal;
            };

            return {
                hours: hoursSetting ? Number(hoursSetting.value) : 24.0,
                enabled: parseBool(enabledSetting?.value, true),
            };
        } catch (_) {
            return {
                hours: 24.0,
                enabled: true,
            };
        }
    }

    async evaluatePendingReviews(): Promise<{
        evaluatedCount: number;
        autoApprovedCount: number;
        skippedCount: number;
        errors: any[];
    }> {
        const settings = await this.getAutoApproveSettings();
        if (!settings.enabled) {
            return { evaluatedCount: 0, autoApprovedCount: 0, skippedCount: 0, errors: [] };
        }

        const pendingSubmissions = await this.submissionRepo.findPendingReviews();
        const now = new Date();
        const timeoutMs = settings.hours * 3600 * 1000;

        let evaluatedCount = 0;
        let autoApprovedCount = 0;
        let skippedCount = 0;
        const errors: any[] = [];

        for (const sub of pendingSubmissions) {
            evaluatedCount++;
            const submissionDate = sub.createdAt ? new Date(sub.createdAt) : null;
            if (!submissionDate || isNaN(submissionDate.getTime())) {
                skippedCount++;
                continue;
            }

            const elapsedMs = now.getTime() - submissionDate.getTime();
            if (elapsedMs >= timeoutMs) {
                try {
                    this.logger.log(
                        `⚡ Auto-approving submission '${sub.id}' (Worker: ${sub.workerId}): Submitted ${((elapsedMs) / 3600000).toFixed(1)}h ago >= threshold of ${settings.hours}h`,
                    );

                    await this.reviewEngine.reviewSubmission(sub.id, {
                        action: 'approved',
                        reviewedBy: 'system_auto_approve',
                        notes: `Auto-approved by system: Review window (${settings.hours}h) elapsed without buyer or admin action.`,
                    });

                    autoApprovedCount++;
                } catch (err: any) {
                    this.logger.error(`Failed to auto-approve submission ${sub.id}: ${err.message}`);
                    errors.push({ submissionId: sub.id, error: err.message });
                }
            } else {
                skippedCount++;
            }
        }

        if (autoApprovedCount > 0) {
            this.logger.log(
                `✅ Review Auto-Approve Cycle completed: ${autoApprovedCount} submissions approved (${skippedCount} still within review window).`,
            );
        }

        return {
            evaluatedCount,
            autoApprovedCount,
            skippedCount,
            errors,
        };
    }
}
