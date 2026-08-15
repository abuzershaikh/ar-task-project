import { Injectable, Inject, forwardRef } from '@nestjs/common';
import { SubmissionRepository } from '../../shared/database/repositories/submission.repository';
import { TaskRepository } from '../../shared/database/repositories/task.repository';
import { WorkerRepository } from '../../shared/database/repositories/worker.repository';
import { EarningEngineService } from '../../earning-engine/earning.service';
import { TaskEngineService } from '../../task-engine/task-engine.service';
import { FraudEngineService } from '../../fraud-engine/fraud.service';
import { NotificationEngineService } from '../../notification-engine/notification.service';
import { Review, ReviewDecision } from '../types';

/**
 * Review decision process karta hai (approve/reject)
 */
@Injectable()
export class ReviewDecisionService {
    constructor(
        private readonly submissionRepo: SubmissionRepository,
        private readonly taskRepo: TaskRepository,
        private readonly workerRepo: WorkerRepository,
        private readonly earningEngine: EarningEngineService,
        private readonly fraudEngine: FraudEngineService,
        private readonly notificationEngine: NotificationEngineService,
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

        // Delegate state machine transitions to TaskEngineService FIRST
        if (action === 'approved') {
            // Fraud Assessment Check before approving
            const isSuspicious = await this.fraudEngine.isSuspicious(submission.workerId, 'SUBMISSION_REVIEW');
            if (isSuspicious) {
                console.warn(`⚠️ High fraud risk score detected for worker ${submission.workerId} on submission ${submissionId}`);
                await this.notificationEngine.sendNotification(
                    'admin',
                    `High fraud risk detected for worker ${submission.workerId} on submission ${submissionId}`,
                    'HIGH_RISK_SUBMISSION',
                    { submissionId, workerId: submission.workerId }
                );
            }

            await this.taskEngine.approveTask({
                taskId: submission.taskId,
                reviewedBy,
                notes,
            });

            // Update Worker progress stats
            await this.workerRepo.incrementTasksCompleted(submission.workerId);

            // Process earning
            const earning = await this.earningEngine.calculateEarning(
                submission.taskId,
                submission.workerId,
            );
            await this.earningEngine.postEarning(earning);

            // Notify Worker
            await this.notificationEngine.sendNotification(
                submission.workerId,
                'Your task submission has been approved! Reward credited to your wallet.',
                'TASK_APPROVED',
                { taskId: submission.taskId, submissionId },
            );

            console.log(`✅ Task approved via state machine: ${submission.taskId}`);
        } else if (action === 'rejected') {
            await this.taskEngine.rejectTask({
                taskId: submission.taskId,
                reviewedBy,
                notes,
            });

            // Update Worker rejection stats
            await this.workerRepo.incrementTasksRejected(submission.workerId);

            // Notify Worker
            await this.notificationEngine.sendNotification(
                submission.workerId,
                `Your task submission was rejected. Reason: ${notes || 'Not specified'}`,
                'TASK_REJECTED',
                { taskId: submission.taskId, submissionId, notes },
            );

            console.log(`❌ Task rejected via state machine: ${submission.taskId}`);
        } else if (action === 'changes_requested') {
            await this.taskEngine.requestChangesTask({
                taskId: submission.taskId,
                reviewedBy,
                notes,
            });

            // Notify Worker
            await this.notificationEngine.sendNotification(
                submission.workerId,
                `Changes requested for your task submission: ${notes || 'Please revise your proof'}`,
                'TASK_CHANGES_REQUESTED',
                { taskId: submission.taskId, submissionId, notes },
            );

            console.log(`🔄 Task changes requested via state machine: ${submission.taskId}`);
        }

        // Update submission ONLY IF task engine succeeds
        await this.submissionRepo.update(submissionId, {
            reviewStatus: action,
            reviewedBy,
            reviewedAt: new Date(),
            reviewNotes: notes,
        });

        return {
            submissionId,
            action,
            reviewedBy,
            reviewedAt: new Date(),
            notes,
        };
    }
}
