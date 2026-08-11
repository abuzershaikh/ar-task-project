import { Task } from './task.interface';

export interface YouTubeTaskData {
    videoId: string;
    videoUrl: string;
    channelId: string;
    channelUrl: string;
}

export interface YouTubeCommentTask extends Task {
    targetData: YouTubeTaskData & {
        commentType: 'positive' | 'specific' | 'question' | 'custom';
        minWords?: number;
        maxWords?: number;
        keywords?: string[];
        avoidKeywords?: string[];
        commentGuidelines?: string;
        exampleComments?: string[];
    };
}

export interface YouTubeWatchTimeTask extends Task {
    targetData: YouTubeTaskData & {
        minWatchTime: number; // in seconds
        watchPercentage?: number; // 0-100
        skipDetection: boolean;
        interactionRequired: boolean;
    };
}

export interface YouTubeSubscribeTask extends Task {
    targetData: YouTubeTaskData & {
        notificationBellRequired: boolean;
        verificationMethod: 'screenshot' | 'api' | 'manual';
    };
}

export interface YouTubeLikeTask extends Task {
    targetData: YouTubeTaskData & {
        verificationMethod: 'screenshot' | 'api' | 'manual';
        commentRequired?: boolean;
    };
}

export interface YouTubeShareTask extends Task {
    targetData: YouTubeTaskData & {
        platforms: string[];
        verificationMethod: 'screenshot' | 'link' | 'manual';
    };
}

export interface YouTubeSubmission {
    taskId: string;
    workerId: string;

    // Common Fields
    screenshot?: string;
    screenshotUrl?: string;

    // Comment Specific
    commentText?: string;
    commentUrl?: string;
    commentId?: string;
    commentTimestamp?: Date;

    // Watch Time Specific
    watchDuration?: number;
    watchPercentage?: number;
    watchStartTime?: Date;
    watchEndTime?: Date;

    // Subscribe Specific
    subscriptionScreenshot?: string;
    notificationBellScreenshot?: string;

    // Share Specific
    shareUrl?: string;
    sharePlatform?: string;
    shareTimestamp?: Date;

    // Metadata
    deviceInfo?: Record<string, any>;
    ipAddress?: string;
    userAgent?: string;

    submittedAt: Date;
}

export interface YouTubeValidationRules {
    type: string;

    // Comment Validation
    minCommentLength?: number;
    maxCommentLength?: number;
    requiredKeywords?: string[];
    prohibitedKeywords?: string[];
    sentimentCheck?: boolean;
    spamCheck?: boolean;

    // Watch Time Validation
    minWatchDuration?: number;
    skipThreshold?: number;

    // General
    screenshotRequired: boolean;
    duplicateCheck: boolean;
    fraudCheck: boolean;
}
