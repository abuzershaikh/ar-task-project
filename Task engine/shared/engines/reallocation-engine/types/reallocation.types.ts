export enum ReleaseReason {
    WORKER_TIMEOUT = 'WORKER_TIMEOUT',
    WORKER_CANCELLED = 'WORKER_CANCELLED',
    ADMIN_CANCELLED = 'ADMIN_CANCELLED',
    CAMPAIGN_CANCELLED = 'CAMPAIGN_CANCELLED',
}

export interface ReallocationConfig {
    campaignAutoExtensionHours: number; // Default: 10 hours if campaign incomplete at expiry date
}

export interface TaskReleaseRequest {
    taskId: string;
    workerId: string;
    campaignId: string;
    reason: ReleaseReason;
    details?: string;
}

export interface PostDeadlineEvaluation {
    evaluatedTasksCount: number;
    expiredTasksCount: number;
    reallocatedTasksCount: number;
    extendedCampaignsCount: number;
}
