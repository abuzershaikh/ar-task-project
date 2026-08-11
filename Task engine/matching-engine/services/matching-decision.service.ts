import { Injectable } from '@nestjs/common';
import { ScoringEngineService } from '../../scoring-engine/scoring.service';
import { RankingEngineService } from '../../ranking-engine/ranking.service';
import { CandidateWorker, MatchingContext, MatchingResult } from '../types';

/**
 * Final matching decision leta hai scoring aur ranking ke basis pe
 */
@Injectable()
export class MatchingDecisionService {
    constructor(
        private readonly scoringEngine: ScoringEngineService,
        private readonly rankingEngine: RankingEngineService,
    ) { }

    async decide(
        candidates: CandidateWorker[],
        context: MatchingContext,
    ): Promise<MatchingResult> {
        if (candidates.length === 0) {
            return {
                taskId: context.taskId,
                matchedWorkers: [],
                totalCandidates: 0,
                filters: [],
                timestamp: new Date(),
            };
        }

        // Step 1: Calculate scores for all candidates
        const workerIds = candidates.map(c => c.workerId);
        const scores = await this.scoringEngine.calculateBatchScores(workerIds);

        // Step 2: Assign scores to candidates
        candidates.forEach(candidate => {
            const score = scores.get(candidate.workerId);
            candidate.score = score ? score.totalScore : 0;
        });

        // Step 3: Rank candidates
        const ranked = await this.rankingEngine.rankWorkers(workerIds, context.taskId);

        // Step 4: Assign ranks
        candidates.forEach(candidate => {
            const rankedWorker = ranked.find(r => r.workerId === candidate.workerId);
            candidate.rank = rankedWorker ? rankedWorker.rank : 999;
        });

        // Step 5: Sort by rank
        candidates.sort((a, b) => a.rank - b.rank);

        console.log(`🎯 Matching complete: ${candidates.length} candidates`);
        console.log(`🏆 Top 3: ${candidates.slice(0, 3).map(c => `${c.workerId}(${c.score})`).join(', ')}`);

        return {
            taskId: context.taskId,
            matchedWorkers: candidates,
            totalCandidates: candidates.length,
            filters: [],
            timestamp: new Date(),
        };
    }
}
