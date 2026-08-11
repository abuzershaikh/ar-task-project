export interface RankedWorker {
    workerId: string;
    score: number;
    rank: number;
    priority: string;
    metadata?: any;
}
