import { Injectable } from '@nestjs/common';
import { TaskReleaseService } from './services/task-release.service';
import { ReassignmentService } from './services/reassignment.service';
import { DeadlineMonitorService } from './services/deadline-monitor.service';
import { TaskReleaseRequest, ReallocationConfig } from './types/reallocation.types';

@Injectable()
export class ReallocationEngine {
    private config: ReallocationConfig = {
        campaignAutoExtensionHours: 10,
    };

    constructor(
        private readonly releaseService: TaskReleaseService,
        private readonly reassignmentService: ReassignmentService,
        private readonly monitorService: DeadlineMonitorService,
    ) { }

    updateConfig(newConfig: Partial<ReallocationConfig>) {
        this.config = { ...this.config, ...newConfig };
    }

    getConfig(): ReallocationConfig {
        return this.config;
    }

    async runMonitorCycle() {
        return this.monitorService.monitorDeadlines(this.config.campaignAutoExtensionHours);
    }

    async processFullTimeouts() {
        return this.monitorService.processFullTimeouts();
    }

    async processCampaignAutoExtensions() {
        return this.monitorService.processCampaignAutoExtensions(this.config.campaignAutoExtensionHours);
    }

    async releaseWorker(request: TaskReleaseRequest) {
        return this.releaseService.releaseWorkerFromTask(request);
    }

    async reassignTask(taskId: string, campaignId: string) {
        return this.reassignmentService.reassignTaskToNewWorker(taskId, campaignId);
    }
}
