export interface TaskContext {
    taskId: string;
    orderId: string;
    campaignId: string;
    taskType: string;
    workerId?: string;
    currentStatus: string;
    targetStatus: string;
    timestamp: Date;
    metadata?: Record<string, any>;
    actor: {
        id: string;
        type: 'worker' | 'buyer' | 'admin' | 'system';
    };
}
