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
}

export interface IContentGenerator {
    generateBatch(count: number, options?: GenerationOptions): Promise<string[]>;
}
