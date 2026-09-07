import { Injectable, Logger } from '@nestjs/common';
import { ScoringEngineService } from '../../scoring-engine/scoring.service';
import { RankingEngineService } from '../../ranking-engine/ranking.service';
import { CandidateWorker, MatchingContext, MatchingResult } from '../types';
import { MIN_SCORE_THRESHOLD } from '../../scoring-engine/types/worker-score';

/**
 * Final matching decision leta hai scoring aur ranking ke basis pe
 * 
 * NEW RULES:
 * - Score < 40 wale workers ko filter out karo (minimum threshold)
 * - 5-tier priority system se rank karo
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

        // Step 3: MINIMUM SCORE FILTER — Score < 40 = no automatic task distribution
        const beforeFilterCount = candidates.length;
        candidates = candidates.filter(c => c.score >= MIN_SCORE_THRESHOLD);
        const filteredOut = beforeFilterCount - candidates.length;

        if (filteredOut > 0) {
            this.logger.log(`🚫 Filtered out ${filteredOut} workers with score < ${MIN_SCORE_THRESHOLD} (minimum threshold)`);
        }

        if (candidates.length === 0) {
            this.logger.warn(`⚠️ All candidates filtered out by minimum score threshold (${MIN_SCORE_THRESHOLD})`);
            return {
                taskId: context.taskId,
                matchedWorkers: [],
                totalCandidates: 0,
                filters: (context.filters || []).map(f => ({ filterName: f, passed: 0, failed: 0, duration: 0 })),
                timestamp: new Date(),
            };
        }

        // Step 4: Rank remaining candidates using fresh scores (5-tier priority)
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

        this.logger.log(`🎯 Matching complete: ${candidates.length} candidates (${filteredOut} filtered by min score)`);
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
