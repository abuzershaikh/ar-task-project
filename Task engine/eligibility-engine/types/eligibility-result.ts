export interface EligibilityResult {
    isEligible: boolean;
    reasons: string[];
    rules?: Record<string, any>;
}
