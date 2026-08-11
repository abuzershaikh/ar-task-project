export interface Review {
    submissionId: string;
    action: 'approved' | 'rejected' | 'pending';
    reviewedBy: string;
    reviewedAt: Date;
    notes?: string;
}

export interface ReviewDecision {
    action: 'approved' | 'rejected';
    reviewedBy: string;
    notes?: string;
}

export enum ReviewMode {
    BUYER = 'buyer',
    ADMIN = 'admin',
    AUTOMATIC = 'automatic',
}
