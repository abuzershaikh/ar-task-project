export interface RankedWorker {
    workerId: string;
    score: number;
    rank: number;
    priority: string;  // 'critical' | 'high' | 'normal' | 'low' | 'very_low'
    activityStatus?: string;  // 'ACTIVE' | 'WARNING' | 'INACTIVE'
    metadata?: any;
}
