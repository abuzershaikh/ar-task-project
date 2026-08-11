import { Injectable } from '@nestjs/common';
import { ReviewAssignmentService } from './services/review-assignment.service';
import { ReviewDecisionService } from './services/review-decision.service';
import { Review, ReviewDecision } from './types';

/**
 * Review Engine
 * Task submission ko review karta hai
 */
@Injectable()
export class ReviewEngineService {
    constructor(
        private readonly assignmentService: ReviewAssignmentService,
        private readonly decisionService: ReviewDecisionService,
    ) { }

    async assignReviewer(submissionId: string): Promise<string> {
        const reviewerId = await this.assignmentService.assign(submissionId);
        return reviewerId;
    }

    async reviewSubmission(
        submissionId: string,
        decision: ReviewDecision,
    ): Promise<Review> {
        const review = await this.decisionService.process(submissionId, decision);
        return review;
    }
}
