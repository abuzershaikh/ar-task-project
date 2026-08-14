import { Injectable, Inject, forwardRef } from '@nestjs/common';
import { SubmissionRepository } from '../../shared/database/repositories/submission.repository';
import { TaskRepository } from '../../shared/database/repositories/task.repository';
import { EarningEngineService } from '../../earning-engine/earning.service';
import { TaskEngineService } from '../../task-engine/task-engine.service';
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
        @Inject(forwardRef(() => TaskEngineService))
        private readonly taskEngine: TaskEngineService,
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

        // Delegate state machine transitions to TaskEngineService
        if (action === 'approved') {
            await this.taskEngine.approveTask({
                taskId: submission.taskId,
                reviewedBy,
                notes,
            });

            // Process earning (Note: if TaskEngine is eventually extended to handle earning, 
            // this can be moved there, but for now we keep it here to satisfy rule 33)
            const earning = await this.earningEngine.calculateEarning(
                submission.taskId,
                submission.workerId,
            );
            await this.earningEngine.postEarning(earning);

            console.log(`✅ Task approved via state machine: ${submission.taskId}`);
        } else if (action === 'rejected') {
            await this.taskEngine.rejectTask({
                taskId: submission.taskId,
                reviewedBy,
                notes,
            });

            console.log(`❌ Task rejected via state machine: ${submission.taskId}`);
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
