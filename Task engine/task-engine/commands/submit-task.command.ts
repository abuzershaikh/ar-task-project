export interface SubmitTaskCommand {
    taskId: string;
    workerId: string;
    data: any;
    proofs?: any;
    metadata?: any;
}
