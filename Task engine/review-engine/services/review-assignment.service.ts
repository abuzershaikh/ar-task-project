import { Injectable } from '@nestjs/common';
import { SubmissionRepository } from '../../shared/database/repositories/submission.repository';
import { OrderRepository } from '../../shared/database/repositories/order.repository';
import { TaskRepository } from '../../shared/database/repositories/task.repository';

/**
 * Submission ko appropriate reviewer assign karta hai
 */
@Injectable()
export class ReviewAssignmentService {
    constructor(
        private readonly submissionRepo: SubmissionRepository,
        private readonly taskRepo: TaskRepository,
        private readonly orderRepo: OrderRepository,
    ) { }

    async assign(submissionId: string): Promise<string> {
        const submission = await this.submissionRepo.findById(submissionId);

        if (!submission) {
            throw new Error('Submission not found');
        }

        const task = await this.taskRepo.findById(submission.taskId);
        if (!task) {
            throw new Error('Task not found');
        }

        const order = await this.orderRepo.findById(task.orderId);
        if (!order) {
            throw new Error('Order not found');
        }

        // Determine reviewer based on review mode
        let reviewerId: string | null = null;

        switch (order.reviewMode) {
            case 'buyer':
                reviewerId = order.buyerId;
                break;

            case 'admin':
                reviewerId = 'admin'; // TODO: Assign to available admin
                break;

            case 'automatic':
                reviewerId = 'system';
                break;

            default:
                throw new Error('Unknown review mode');
        }

        // Update submission
        await this.submissionRepo.update(submissionId, {
            reviewedBy: reviewerId,
            reviewStatus: 'pending',
        });

        console.log(`📋 Review assigned: ${submissionId} → ${reviewerId}`);

        return reviewerId;
    }
}
