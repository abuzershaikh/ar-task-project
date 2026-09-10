export interface SubmitTaskCommand {
    taskId: string;
    workerId: string;
    workerEmail?: string;
    data: any;
    proofs?: any;
    metadata?: any;
}
