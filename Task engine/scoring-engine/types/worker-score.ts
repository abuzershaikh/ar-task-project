export interface WorkerScore {
    workerId: string;
    totalScore: number;
    completionScore: number;
    qualityScore: number;
    reliabilityScore: number;
    ratingScore: number;
    experienceScore: number;
    breakdown: {
        completion: number;
        quality: number;
        reliability: number;
        rating: number;
        experience: number;
    };
}

export interface ScoreFeatures {
    completion: number;
    quality: number;
    reliability: number;
    rating: number;
    experience: number;
}

/**
 * New score weights as per spec:
 * Completion 35%, Quality 25%, Reliability 20%, Rating 10%, Experience 10%
 */
export interface ScoreWeights {
    completion: number;  // 0.35
    quality: number;     // 0.25
    reliability: number; // 0.20
    rating: number;      // 0.10
    experience: number;  // 0.10
}

export const DEFAULT_SCORE_WEIGHTS: ScoreWeights = {
    completion: 0.35,
    quality: 0.25,
    reliability: 0.20,
    rating: 0.10,
    experience: 0.10,
};

// Minimum score threshold for task distribution
export const MIN_SCORE_THRESHOLD = 40;

// Performance point values
export const PERFORMANCE_POINTS = {
    TASK_COMPLETED: 1,
    TASK_REJECTED: -3,
    TASK_EXPIRED: -5,
};
