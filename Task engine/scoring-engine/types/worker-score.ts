export interface WorkerScore {
    workerId: string;
    totalScore: number;
    qualityScore: number;
    completionScore: number;
    reliabilityScore: number;
    ratingScore: number;
    recentPerformanceScore: number;
    experienceScore: number;
    breakdown: {
        quality: number;
        completion: number;
        reliability: number;
        rating: number;
        recent: number;
        experience: number;
    };
}

export interface ScoreFeatures {
    quality: number;
    completion: number;
    reliability: number;
    rating: number;
    recent: number;
    experience: number;
}

export interface ScoreWeights {
    quality: number;
    completion: number;
    reliability: number;
    rating: number;
    recent: number;
    experience: number;
}
