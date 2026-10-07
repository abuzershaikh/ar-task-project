export interface GenerationOptions {
    topic?: string;
    language?: string; // 'English', 'Hindi', 'Hinglish', 'Spanish', etc.
    tone?: string;     // 'natural', 'enthusiastic', 'professional', 'questioning', 'detailed'
    uniqueness?: boolean;
    videoTitle?: string;
    channelName?: string;
    appName?: string;
    appDescription?: string;
    isAppReview?: boolean;
    generatorType?: string;
    model?: string;
    apiKey?: string;
    minWords?: number;
    maxWords?: number;
    /** Existing accepted comments that regenerated content must not resemble. */
    avoidComments?: string[];
    /** Included in the AI prompt when only duplicate slots are being replaced. */
    regenerationAttempt?: number;
}

export interface IContentGenerator {
    generateBatch(count: number, options?: GenerationOptions): Promise<string[]>;
}
