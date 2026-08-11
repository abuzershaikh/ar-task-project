import { Injectable } from '@nestjs/common';
import { EligibilityResult } from './types/eligibility-result';

/**
 * Eligibility Engine
 * Worker task ke liye eligible hai ya nahi check karta hai
 */
@Injectable()
export class EligibilityEngineService {
    constructor() { }

    async checkEligibility(
        workerId: string,
        taskId: string,
    ): Promise<EligibilityResult> {
        // All eligibility rules check karenge
        const results = {
            isEligible: true,
            reasons: [],
            rules: {},
        };

        return results;
    }

    async batchCheckEligibility(
        workerIds: string[],
        taskId: string,
    ): Promise<Map<string, EligibilityResult>> {
        const results = new Map<string, EligibilityResult>();

        for (const workerId of workerIds) {
            const result = await this.checkEligibility(workerId, taskId);
            results.set(workerId, result);
        }

        return results;
    }
}
