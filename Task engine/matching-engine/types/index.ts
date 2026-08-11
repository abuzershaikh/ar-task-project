export interface MatchingRequest {
    taskId: string;
    orderId?: string;
    limit?: number;
    context?: any;
}

export interface MatchingResult {
    taskId: string;
    matchedWorkers: CandidateWorker[];
    totalCandidates: number;
    filters: FilterResult[];
    timestamp: Date;
}

export interface CandidateWorker {
    workerId: string;
    score: number;
    rank: number;
    eligible: boolean;
    filterResults: Record<string, boolean>;
    metadata?: any;
}

export interface FilterResult {
    filterName: string;
    passed: number;
    failed: number;
    duration: number;
}

export interface MatchingContext {
    taskId: string;
    task: any;
    order: any;
    requirements: any;
    filters: string[];
}
