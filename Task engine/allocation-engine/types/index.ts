export interface AllocationRequest {
    taskIds: string[];
    workerIds: string[];
    strategy: 'sequential' | 'batch' | 'balanced' | 'priority';
}

export interface AllocationResult {
    assignments: TaskAssignment[];
    successCount: number;
    failedCount: number;
    timestamp: Date;
}

export interface TaskAssignment {
    taskId: string;
    workerId: string;
    assignedAt: Date;
    metadata?: any;
}
