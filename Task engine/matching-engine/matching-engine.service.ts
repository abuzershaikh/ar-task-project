import { Injectable } from '@nestjs/common';
import { CandidateService } from './services/candidate.service';
import { MatchingContextService } from './services/matching-context.service';
import { MatchingDecisionService } from './services/matching-decision.service';
import { MatchingRequest, MatchingResult } from './types';

/**
 * Matching Engine
 * Task ke liye eligible workers find karta hai aur priority decide karta hai
 */
@Injectable()
export class MatchingEngineService {
    constructor(
        private readonly candidateService: CandidateService,
        private readonly contextService: MatchingContextService,
        private readonly decisionService: MatchingDecisionService,
    ) { }

    async matchWorkersForTask(request: MatchingRequest): Promise<MatchingResult> {
        // 1. Context build karo
        const context = await this.contextService.buildContext(request);

        // 2. Candidate workers find karo
        const candidates = await this.candidateService.findCandidates(context);

        // 3. Matching decision lo
        const result = await this.decisionService.decide(candidates, context);

        return result;
    }

    async matchWorkersForBatch(taskIds: string[]): Promise<Map<string, MatchingResult>> {
        const results = new Map<string, MatchingResult>();

        for (const taskId of taskIds) {
            const result = await this.matchWorkersForTask({ taskId });
            results.set(taskId, result);
        }

        return results;
    }
}
