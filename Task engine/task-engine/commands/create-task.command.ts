export interface CreateTaskCommand {
    orderId: string;
    campaignId: string;
    taskType: string;
    rewardAmount: number;
    requirements?: any;
    metadata?: any;
    deadline?: Date;
    status?: string;
}
