import { Injectable } from '@nestjs/common';
import { SubmissionRepository } from '../../shared/database/repositories/submission.repository';
import { TaskRepository } from '../../shared/database/repositories/task.repository';
import { EarningEngineService } from '../../earning-engine/earning.service';
import { Review, ReviewDecision } from '../types';

/**
 * Review decision process karta hai (approve/reject)
 */
@Injectable()
export class ReviewDecisionService {
    constructor(
        private readonly submissionRepo: SubmissionRepository,
        private readonly taskRepo: TaskRepository,
        private readonly earningEngine: EarningEngineService,
    ) { }

    async process(
        submissionId: string,
        decision: ReviewDecision,
    ): Promise<Review> {
        const submission = await this.submissionRepo.findById(submissionId);

        if (!submission) {
            throw new Error('Submission not found');
        }

        const { action, notes, reviewedBy } = decision;

        // Update submission
        await this.submissionRepo.update(submissionId, {
            reviewStatus: action,
            reviewedBy,
            reviewedAt: new Date(),
            reviewNotes: notes,
        });

        // Update task status
        if (action === 'approved') {
            await this.taskRepo.update(submission.taskId, {
                status: 'completed',
                completedAt: new Date(),
            });

            // Process earning
            const earning = await this.earningEngine.calculateEarning(
                submission.taskId,
                submission.workerId,
            );
            await this.earningEngine.postEarning(earning);

            console.log(`✅ Task approved: ${submission.taskId}`);
        } else if (action === 'rejected') {
            await this.taskRepo.update(submission.taskId, {
                status: 'rejected',
            });

            console.log(`❌ Task rejected: ${submission.taskId}`);
        }

        return {
            submissionId,
            action,
            reviewedBy,
            reviewedAt: new Date(),
            notes,
        };
    }
}
