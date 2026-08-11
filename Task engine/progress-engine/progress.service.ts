import { Injectable } from '@nestjs/common';
import { OrderProgressService } from './services/order-progress.service';
import { CampaignProgressService } from './services/campaign-progress.service';
import { WorkerProgressService } from './services/worker-progress.service';

/**
 * Progress Engine
 * Order, Campaign, Worker ka progress track karta hai
 */
@Injectable()
export class ProgressEngineService {
    constructor(
        private readonly orderProgress: OrderProgressService,
        private readonly campaignProgress: CampaignProgressService,
        private readonly workerProgress: WorkerProgressService,
    ) { }

    async getOrderProgress(orderId: string) {
        return this.orderProgress.getProgress(orderId);
    }

    async getCampaignProgress(campaignId: string) {
        return this.campaignProgress.getProgress(campaignId);
    }

    async getWorkerProgress(workerId: string) {
        return this.workerProgress.getProgress(workerId);
    }
}
