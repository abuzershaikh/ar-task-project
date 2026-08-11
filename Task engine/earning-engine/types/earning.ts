export interface Earning {
    id: string | null;
    workerId: string;
    taskId: string;
    amount: number;
    type: string;
    status: EarningStatus;
    metadata?: any;
    ledgerEntryId?: string;
    createdAt?: Date;
}

export enum EarningStatus {
    PENDING = 'pending',
    POSTED = 'posted',
    REVERSED = 'reversed',
    FAILED = 'failed',
}

export interface EarningPosting {
    earningId: string;
    amount: number;
    workerId: string;
    ledgerEntryId: string;
    postedAt: Date;
}
