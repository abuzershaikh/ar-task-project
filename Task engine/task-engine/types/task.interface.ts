import { TaskStatus } from './task-status.enum';
import { TaskType, TaskCategory } from './task-type.enum';

export interface Task {
    id: string;
    orderId: string;
    campaignId: string;
    buyerId: string;
    organizationId: string;

    // Task Definition
    type: TaskType;
    category: TaskCategory;
    title: string;
    description: string;
    instructions: string;

    // Requirements
    requirements: TaskRequirements;

    // Reward
    rewardAmount: number;
    rewardCurrency: string;
    rewardSnapshotId?: string;

    // Target & Progress
    targetData: Record<string, any>;
    metadata: Record<string, any>;

    // Status & Lifecycle
    status: TaskStatus;
    priority: number;

    // Assignment
    assignedTo?: string;
    assignedAt?: Date;

    // Deadlines
    expiresAt?: Date;
    acceptByDeadline?: Date;
    submitByDeadline?: Date;

    // Attempts
    maxAttempts: number;
    currentAttempt: number;

    // Timestamps
    createdAt: Date;
    updatedAt: Date;
    startedAt?: Date;
    submittedAt?: Date;
    completedAt?: Date;

    // Soft Delete
    deletedAt?: Date;
}

export interface TaskRequirements {
    // Location
    countries?: string[];
    states?: string[];
    cities?: string[];

    // Demographics
    minAge?: number;
    maxAge?: number;
    gender?: string[];
    languages?: string[];

    // Experience
    minRating?: number;
    minCompletionRate?: number;
    minTasksCompleted?: number;
    categories?: string[];

    // Account Requirements
    kycRequired: boolean;
    verifiedEmailRequired: boolean;
    verifiedPhoneRequired: boolean;

    // Custom
    customRules?: Record<string, any>;
}

export interface TaskContext {
    task: Task;
    worker?: any;
    submission?: any;
    proof?: any;
    metadata?: Record<string, any>;
}
