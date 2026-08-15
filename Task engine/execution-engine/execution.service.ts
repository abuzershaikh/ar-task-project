import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { TaskEngineService } from '../task-engine/task-engine.service';
import { SubmissionRepository } from '../shared/database/repositories/submission.repository';
import { ReviewEngineService } from '../review-engine/review.service';
import { TaskRepository } from '../shared/database/repositories/task.repository';

@Injectable()
export class ExecutionEngineService {
    constructor(
        private readonly taskEngine: TaskEngineService,
        private readonly submissionRepo: SubmissionRepository,
        private readonly reviewEngine: ReviewEngineService,
        private readonly taskRepo: TaskRepository,
    ) { }

    async startTaskExecution(taskId: string, workerId: string) {
        // Delegate state transition
        await this.taskEngine.startTask({ taskId, workerId });

        // Record telemetry/execution start time
        const task = await this.taskRepo.findById(taskId);
        if (task) {
            await this.taskRepo.update(taskId, {
                metadata: {
                    ...task.metadata,
                    executionStartedAt: new Date().toISOString()
                }
            });
        }
    }

    async submitTaskExecution(
        taskId: string,
        workerId: string,
        payload: { data: any; proofs: { fileId: string; url: string }[] }
    ) {
        if (!payload.data || !payload.proofs) {
            throw new BadRequestException('Invalid submission format. Expected { data: {}, proofs: [] }');
        }

        const task = await this.taskRepo.findById(taskId);
        if (!task) {
            throw new BadRequestException('Task not found');
        }

        // Anti-fraud execution time check
        const executionStartedAt = task.metadata?.executionStartedAt;
        if (executionStartedAt) {
            const startedAt = new Date(executionStartedAt).getTime();
            const now = Date.now();
            const durationMs = now - startedAt;

            // Hardcoded 5 seconds minimum for any task as anti-bot measure
            if (durationMs < 5000) {
                throw new BadRequestException('Submission rejected: Task completed suspiciously fast (bot detected).');
            }
        }

        // Mark task as submitted in task engine
        await this.taskEngine.submitTask({
            taskId,
            workerId,
            data: {
                ...payload.data,
                proofs: payload.proofs,
                executionDurationMs: executionStartedAt ? Date.now() - new Date(executionStartedAt).getTime() : null,
            },
        });

        // Create the TaskSubmission record
        let submission = await this.submissionRepo.findByTaskId(taskId);
        if (!submission) {
            submission = await this.submissionRepo.create({
                taskId,
                workerId,
                data: payload.data,
                proofs: payload.proofs,
                status: 'submitted',
                reviewStatus: 'pending'
            });
        } else {
            await this.submissionRepo.update(submission.id, {
                data: payload.data,
                proofs: payload.proofs,
                status: 'submitted',
                reviewStatus: 'pending'
            });
        }

        // Delegate to Review Engine to assign the reviewer (Buyer, Admin, or System)
        await this.reviewEngine.assignReviewer(submission.id);

        return submission;
    }

    async resubmitTaskExecution(
        taskId: string,
        workerId: string,
        payload: { data: any; proofs: { fileId: string; url: string }[]; resubmissionNotes?: string }
    ) {
        let submission = await this.submissionRepo.findByTaskId(taskId);
        if (!submission || submission.workerId !== workerId) {
            throw new NotFoundException('Previous submission not found');
        }

        await this.taskEngine.submitTask({
            taskId,
            workerId,
            data: {
                ...payload.data,
                proofs: payload.proofs || submission.proofs,
                resubmissionNotes: payload.resubmissionNotes,
                isResubmission: true,
            },
        });

        // Update submission record
        await this.submissionRepo.update(submission.id, {
            data: payload.data,
            proofs: payload.proofs || submission.proofs,
            status: 'submitted',
            reviewStatus: 'pending'
        });

        // Re-assign for review
        await this.reviewEngine.assignReviewer(submission.id);

        return submission;
    }
}
