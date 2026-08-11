export interface ApproveTaskCommand {
    taskId: string;
    reviewedBy?: string;
    notes?: string;
}
