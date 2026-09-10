export interface AcceptTaskCommand {
    taskId: string;
    workerId: string;
    workerEmail?: string;
    orderUnitId?: string;
}
