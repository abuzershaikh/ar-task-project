export interface Review {
    submissionId: string;
    action: 'approved' | 'rejected' | 'pending' | 'changes_requested';
    reviewedBy: string;
    reviewedAt: Date;
    notes?: string;
}

export interface ReviewDecision {
    action: 'approved' | 'rejected' | 'changes_requested';
    reviewedBy: string;
    notes?: string;
}

export enum ReviewMode {
    BUYER = 'buyer',
    ADMIN = 'admin',
    AUTOMATIC = 'automatic',
}
