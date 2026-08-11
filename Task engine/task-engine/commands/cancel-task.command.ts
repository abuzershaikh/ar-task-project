export interface CancelTaskCommand {
    taskId: string;
    reason?: string;
    actorId?: string;
}
