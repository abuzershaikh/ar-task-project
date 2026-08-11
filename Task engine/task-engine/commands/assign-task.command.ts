export interface AssignTaskCommand {
    taskId: string;
    workerId: string;
    actorId?: string;
    metadata?: any;
}
