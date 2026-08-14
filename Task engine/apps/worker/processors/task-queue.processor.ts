import { Processor, Process, InjectQueue } from '@nestjs/bull';
import { Job, Queue } from 'bull';
import { Injectable, Logger } from '@nestjs/common';
import { TaskEngineService } from '../../../task-engine/task-engine.service';
import { TaskGenerationJobRepository } from '../../../shared/database/repositories/task-generation-job.repository';
import { TaskGenerationJobStatus } from '../../../shared/database/entities/task-generation-job.entity';

/**
 * Task queue processor
 * Background mein tasks create aur process karta hai
 */
@Processor('task')
@Injectable()
export class TaskQueueProcessor {
    private readonly logger = new Logger(TaskQueueProcessor.name);

    constructor(
        private readonly taskEngine: TaskEngineService,
        private readonly jobRepo: TaskGenerationJobRepository,
        @InjectQueue('matching') private readonly matchingQueue: Queue,
    ) { }

    @Process('create-tasks')
    async handleCreateTasks(job: Job) {
        const { orderId, count, taskType, requirements, rewardAmount, jobId } = job.data;

        this.logger.log(`📝 Processing 'create-tasks' job from Redis Queue. Creating ${count} tasks for Order '${orderId}'`);

        try {
            const createdTasks = [];
            for (let i = 0; i < count; i++) {
                const taskReqs = {
                    ...(requirements || {}),
                    sequenceIndex: i,
                    orderIdSequence: `${orderId}_task_${i + 1}`,
                };

                const task = await this.taskEngine.createTask({
                    orderId,
                    campaignId: orderId,
                    taskType: taskType || 'DEFAULT',
                    requirements: taskReqs,
                    rewardAmount: rewardAmount || 5,
                });
                createdTasks.push(task);
            }

            // Update TaskGenerationJob status in DB to COMPLETED
            if (jobId) {
                await this.jobRepo.updateProgress(jobId, count, TaskGenerationJobStatus.COMPLETED);
            }

            this.logger.log(`✅ Bull Worker created ${count} tasks in MySQL for Order '${orderId}'`);

            // Chain to matching queue to match workers for the order tasks
            if (createdTasks.length > 0) {
                await this.matchingQueue.add('batch-match', {
                    orderId,
                    batchSize: 50,
                });
                this.logger.log(`🎯 Enqueued 'batch-match' job for Order '${orderId}'`);
            }

            return { success: true, count, orderId };
        } catch (error) {
            this.logger.error(`Failed to create tasks for Order '${orderId}': ${error.message}`, error.stack);
            if (jobId) {
                await this.jobRepo.updateProgress(jobId, 0, TaskGenerationJobStatus.FAILED, error.message);
            }
            throw error;
        }
    }

    @Process('expire-tasks')
    async handleExpireTasks(job: Job) {
        this.logger.log('⏰ Checking for expired tasks...');
        return { success: true };
    }
}
