import { Processor, Process, InjectQueue } from '@nestjs/bull';
import { Job, Queue } from 'bull';
import { Injectable, Logger } from '@nestjs/common';
import { TaskEngineService } from '../../../task-engine/task-engine.service';
import { RewardEngineService } from '../../../reward-engine/reward.service';
import { TaskGenerationJobRepository } from '../../../shared/database/repositories/task-generation-job.repository';
import { TaskGenerationJobStatus } from '../../../shared/database/entities/task-generation-job.entity';
import { DeadlineMonitorService } from '../../../shared/engines/reallocation-engine/services/deadline-monitor.service';

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
        private readonly rewardEngine: RewardEngineService,
        private readonly jobRepo: TaskGenerationJobRepository,
        private readonly deadlineMonitor: DeadlineMonitorService,
        @InjectQueue('matching') private readonly matchingQueue: Queue,
    ) { }

    @Process('create-tasks')
    async handleCreateTasks(job: Job) {
        const { orderId, count, taskType, requirements, rewardAmount, jobId } = job.data;

        this.logger.log(`📝 Processing 'create-tasks' job from Redis Queue for Order '${orderId}'`);

        try {
            let currentGenerated = 0;
            const jobRecord = await this.jobRepo.findByOrderId(orderId);
            if (jobRecord) {
                currentGenerated = jobRecord.generatedTasksCount || 0;
                if (currentGenerated >= count) {
                    this.logger.log(`Tasks already fully generated (${currentGenerated}/${count}) for Order '${orderId}'. Skipping duplicate generation.`);
                    return { success: true, count, orderId, matchingEnqueued: false };
                }
            }

            const remainingCount = count - currentGenerated;
            this.logger.log(`Creating ${remainingCount} tasks (already generated: ${currentGenerated}) for Order '${orderId}'`);

            const createdTasks = [];
            for (let i = currentGenerated; i < count; i++) {
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

                // Lock reward snapshot at task creation time to prevent pricing drift
                try {
                    await this.rewardEngine.createSnapshot(task.id);
                } catch (snapshotErr) {
                    this.logger.warn(`Failed to create reward snapshot for task '${task.id}': ${snapshotErr.message}. Falling back to task.rewardAmount at earning time.`);
                }
            }

            // Update TaskGenerationJob status in DB to COMPLETED
            if (jobId) {
                await this.jobRepo.updateProgress(jobId, currentGenerated + createdTasks.length, TaskGenerationJobStatus.COMPLETED);
            }

            this.logger.log(`✅ Bull Worker created ${count} tasks in MySQL for Order '${orderId}'`);

            // Chain to matching queue to match workers for the order tasks
            let matchingEnqueued = false;
            if (createdTasks.length > 0) {
                try {
                    await this.matchingQueue.add(
                        'batch-match',
                        { orderId, batchSize: 50 },
                        {
                            attempts: 3,
                            backoff: {
                                type: 'exponential',
                                delay: 2000,
                            },
                            removeOnComplete: 100,
                            removeOnFail: 500,
                        },
                    );
                    matchingEnqueued = true;
                    this.logger.log(`🎯 Enqueued 'batch-match' job for Order '${orderId}' with exponential backoff retries`);
                } catch (matchingError) {
                    this.logger.error(`⚠️ Tasks created successfully, but failed to enqueue matching job for Order '${orderId}': ${matchingError.message}`, matchingError.stack);
                }
            }

            return { success: true, count, orderId, matchingEnqueued };
        } catch (error) {
            this.logger.error(`Failed to create tasks for Order '${orderId}': ${error.message}`, error.stack);
            if (jobId) {
                // Do NOT reset generatedTasksCount to 0! Query existing tasks or keep actual generated count to prevent duplicate creation on Bull retry.
                const jobRecord = await this.jobRepo.findByOrderId(orderId);
                const actualGenerated = jobRecord ? jobRecord.generatedTasksCount : 0;
                await this.jobRepo.updateProgress(jobId, actualGenerated, TaskGenerationJobStatus.FAILED, error.message);
            }
            throw error;
        }
    }

    @Process('expire-tasks')
    async handleExpireTasks(job: Job) {
        this.logger.log('⏰ Executing Post-Deadline Task Expiration & Reallocation cycle...');
        try {
            const result = await this.deadlineMonitor.monitorDeadlines();
            this.logger.log(`✅ Expired task cycle result: Evaluated ${result.evaluatedTasksCount}, Expired ${result.expiredTasksCount}, Reallocated ${result.reallocatedTasksCount}, Extended Campaigns ${result.extendedCampaignsCount}`);
            return { success: true, ...result };
        } catch (error) {
            this.logger.error(`Failed executing expired tasks cycle: ${error.message}`, error.stack);
            throw error;
        }
    }
}

