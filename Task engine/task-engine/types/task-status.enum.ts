export enum TaskStatus {
    DRAFT = 'draft',
    ACTIVE = 'active',
    ASSIGNED = 'assigned',
    ACCEPTED = 'accepted',
    IN_PROGRESS = 'in_progress',
    SUBMITTED = 'submitted',
    UNDER_REVIEW = 'under_review',
    APPROVED = 'approved',
    REJECTED = 'rejected',
    CANCELLED = 'cancelled',
    EXPIRED = 'expired',
    FAILED = 'failed'
}

export const TERMINAL_STATUSES = [
    TaskStatus.APPROVED,
    TaskStatus.CANCELLED,
    TaskStatus.EXPIRED,
    TaskStatus.FAILED
];

export const ACTIVE_STATUSES = [
    TaskStatus.ACTIVE,
    TaskStatus.ASSIGNED,
    TaskStatus.ACCEPTED,
    TaskStatus.IN_PROGRESS,
    TaskStatus.SUBMITTED,
    TaskStatus.UNDER_REVIEW
];
