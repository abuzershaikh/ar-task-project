import { Injectable, Logger } from '@nestjs/common';
import { ScoringEngineService } from '../../scoring-engine/scoring.service';
import { RankingEngineService } from '../../ranking-engine/ranking.service';
import { CandidateWorker, MatchingContext, MatchingResult } from '../types';

/**
 * Final matching decision leta hai scoring aur ranking ke basis pe
 * 
 * RULES:
 * - Every otherwise eligible worker remains eligible, regardless of score.
 * - 5-tier priority system ranks higher-scoring workers first.
 * - Activity deprioritization ranking me apply hota hai
 */
@Injectable()
export class MatchingDecisionService {
    private readonly logger = new Logger(MatchingDecisionService.name);

    constructor(
        private readonly scoringEngine: ScoringEngineService,
        private readonly rankingEngine: RankingEngineService,
    ) { }

    async decide(
        candidates: CandidateWorker[],
        context: MatchingContext,
        preloadedWorkers?: any[],
    ): Promise<MatchingResult> {
        if (candidates.length === 0) {
            return {
                taskId: context.taskId,
                matchedWorkers: [],
                totalCandidates: 0,
                filters: (context.filters || []).map(f => ({ filterName: f, passed: 0, failed: 0, duration: 0 })),
                timestamp: new Date(),
            };
        }

        // Step 1: Calculate scores for all candidates
        const workerIds = candidates.map(c => c.workerId);
        const scores = await this.scoringEngine.calculateBatchScores(workerIds, preloadedWorkers);

        // Step 2: Assign scores to candidates and prepare map for ranking
        const freshScoresMap = new Map<string, number>();
        candidates.forEach(candidate => {
            const score = scores.get(candidate.workerId);
            const totalScore = score && typeof score.totalScore === 'number' ? score.totalScore : 50;
            candidate.score = totalScore;
            freshScoresMap.set(candidate.workerId, totalScore);
        });

        // Step 3: Score is a ranking signal, not an eligibility gate. Low-score
        // workers can still receive tasks after the normal active/KYC/capacity/
        // duplicate checks have passed.

        // Step 4: Rank all eligible candidates using fresh scores (5-tier priority)
        const rankedWorkerIds = candidates.map(c => c.workerId);
        const rankedScoresMap = new Map<string, number>();
        candidates.forEach(c => rankedScoresMap.set(c.workerId, c.score));

        const ranked = await this.rankingEngine.rankWorkers(rankedWorkerIds, context.taskId, rankedScoresMap);

        // Step 5: Assign ranks
        candidates.forEach(candidate => {
            const rankedWorker = ranked.find(r => r.workerId === candidate.workerId);
            candidate.rank = rankedWorker ? rankedWorker.rank : 999;
        });

        // Step 6: Sort by rank
        candidates.sort((a, b) => a.rank - b.rank);

        this.logger.log(`🎯 Matching complete: ${candidates.length} eligible candidates ranked by score`);
        this.logger.log(`🏆 Top 3: ${candidates.slice(0, 3).map(c => `${c.workerId}(score:${c.score})`).join(', ')}`);

        return {
            taskId: context.taskId,
            matchedWorkers: candidates,
            totalCandidates: candidates.length,
            filters: (context.filters || []).map(f => ({ filterName: f, passed: 0, failed: 0, duration: 0 })),
            timestamp: new Date(),
        };
    }
}
