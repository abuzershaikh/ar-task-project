export interface RejectTaskCommand {
    taskId: string;
    reviewedBy?: string;
    notes?: string;
}
