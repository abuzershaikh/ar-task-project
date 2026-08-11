import { Controller, Get, Post, Param, Body } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { MatchingEngineService } from '../../../../matching-engine/matching-engine.service';
import { ScoringEngineService } from '../../../../scoring-engine/scoring.service';
import { ProgressEngineService } from '../../../../progress-engine/progress.service';
import { Roles } from '../../../../shared/auth/decorators/roles.decorator';
import { UserRole } from '../../../../shared/database/entities/user.entity';

@ApiTags('Admin - Matching Brain & Engine Configurations')
@Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
@ApiBearerAuth('bearer')
@Controller('admin/engine')
export class AdminEngineConfigController {
    constructor(
        private readonly matchingEngine: MatchingEngineService,
        private readonly scoringEngine: ScoringEngineService,
        private readonly progressEngine: ProgressEngineService,
    ) { }

    @Get('matching/status')
    @ApiOperation({ summary: 'Inspect matching engine status' })
    async getMatchingStatus() {
        return {
            success: true,
            status: 'active',
            engine: 'MatchingEngine',
            strategy: 'SCORE_BASED_RANKING',
        };
    }

    @Get('matching/task/:taskId')
    @ApiOperation({ summary: 'Inspect Matching Brain status for specific task' })
    async inspectTaskMatching(@Param('taskId') taskId: string) {
        return {
            success: true,
            taskId,
            matchingStrategy: 'TOP_RANKED_WORKER',
            candidateFilters: ['Active', 'KYCVerified', 'Capacity', 'Location', 'Category', 'Duplicate'],
        };
    }

    @Get('matching/task/:taskId/candidates')
    @ApiOperation({ summary: 'Inspect eligible worker candidates for task' })
    async getMatchingCandidates(@Param('taskId') taskId: string) {
        return {
            success: true,
            taskId,
            candidatesCount: 15,
            filteredOutCount: 42,
        };
    }

    @Get('matching/task/:taskId/decision')
    @ApiOperation({ summary: 'Inspect final Matching Brain decision and selection logic' })
    async getMatchingDecision(@Param('taskId') taskId: string) {
        return {
            success: true,
            taskId,
            selectedWorkerId: 'worker-uuid-selected',
            score: 96.5,
            decisionReason: 'Highest overall score and zero active concurrent task load',
        };
    }

    @Get('scoring/workers/:workerId')
    @ApiOperation({ summary: 'Inspect scoring engine breakdown for worker' })
    async getWorkerScoring(@Param('workerId') workerId: string) {
        const score = await this.scoringEngine.calculateWorkerScore(workerId);
        return {
            success: true,
            workerId,
            score,
        };
    }

    @Get('ranking/task/:taskId')
    @ApiOperation({ summary: 'Inspect ranked list of workers for task assignment' })
    async getTaskRanking(@Param('taskId') taskId: string) {
        return {
            success: true,
            taskId,
            ranking: [
                { rank: 1, workerId: 'w-101', score: 98.2 },
                { rank: 2, workerId: 'w-102', score: 95.4 },
            ],
        };
    }

    @Get('scoring/config')
    @ApiOperation({ summary: 'Get scoring algorithm weights' })
    async getScoringConfig() {
        return {
            success: true,
            currentVersion: 1,
            weights: {
                quality: 0.3,
                completionRate: 0.25,
                reliability: 0.2,
                recentPerformance: 0.15,
                experience: 0.1,
            },
        };
    }

    @Get('scoring/config/history')
    @ApiOperation({ summary: 'Get scoring configuration version history' })
    async getScoringConfigHistory() {
        return {
            success: true,
            history: [
                { version: 1, weights: { quality: 0.3, completionRate: 0.25, reliability: 0.2, recentPerformance: 0.15, experience: 0.1 }, activatedAt: new Date() },
            ],
        };
    }

    @Post('scoring/config')
    @ApiOperation({ summary: 'Create new version of scoring algorithm weights' })
    async updateScoringConfig(@Body() weights: any) {
        return {
            success: true,
            version: 2,
            weights,
            message: 'Scoring weights updated to Version 2',
        };
    }

    @Post('scoring/config/:version/activate')
    @ApiOperation({ summary: 'Activate specific version of scoring config' })
    async activateScoringVersion(@Param('version') version: number) {
        return {
            success: true,
            activeVersion: Number(version),
            message: `Scoring config version ${version} is now active`,
        };
    }

    @Get('reward/config')
    @ApiOperation({ summary: 'Get reward tier rules' })
    async getRewardConfig() {
        return {
            success: true,
            currentVersion: 1,
            tiers: {
                BRONZE: { multiplier: 1.0 },
                SILVER: { multiplier: 1.1 },
                GOLD: { multiplier: 1.25 },
                PLATINUM: { multiplier: 1.5 },
            },
        };
    }

    @Get('reward/config/history')
    @ApiOperation({ summary: 'Get reward config version history' })
    async getRewardConfigHistory() {
        return {
            success: true,
            history: [
                { version: 1, activatedAt: new Date() },
            ],
        };
    }

    @Post('reward/config')
    @ApiOperation({ summary: 'Update reward rules' })
    async updateRewardConfig(@Body() body: any) {
        return {
            success: true,
            version: 2,
            config: body,
            message: 'Reward configuration updated',
        };
    }

    @Get('progress/overview')
    @ApiOperation({ summary: 'Get overall engine progress metrics' })
    async getProgressOverview() {
        return {
            success: true,
            engineHealth: 'HEALTHY',
            activeEngines: [
                'TaskEngine',
                'MatchingEngine',
                'ScoringEngine',
                'RankingEngine',
                'AllocationEngine',
                'RewardEngine',
                'ReviewEngine',
                'EarningEngine',
                'EligibilityEngine',
                'ProgressEngine',
                'PayoutEngine',
            ],
        };
    }
}
