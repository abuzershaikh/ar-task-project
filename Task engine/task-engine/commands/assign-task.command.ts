export interface AssignTaskCommand {
    taskId: string;
    workerId: string;
    workerEmail?: string;
    orderUnitId?: string;
    actorId?: string;
    metadata?: any;
}
