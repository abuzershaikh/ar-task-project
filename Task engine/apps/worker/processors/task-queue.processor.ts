import { Processor, Process } from '@nestjs/bull';
import { Job } from 'bull';
import { Injectable } from '@nestjs/common';
import { TaskEngineService } from '../../../task-engine/task-engine.service';

/**
 * Task queue processor
 * Background mein tasks create aur process karta hai
 */
@Processor('task')
@Injectable()
export class TaskQueueProcessor {
    constructor(private readonly taskEngine: TaskEngineService) { }

    @Process('create-tasks')
    async handleCreateTasks(job: Job) {
        const { orderId, count } = job.data;

        console.log(`📝 Creating ${count} tasks for order ${orderId}`);

        try {
            // Create tasks
            for (let i = 0; i < count; i++) {
                await this.taskEngine.createTask({
                    orderId,
                    campaignId: orderId,
                    taskType: job.data.taskType || 'DEFAULT',
                    requirements: job.data.requirements,
                    rewardAmount: job.data.rewardAmount || 0,
                });
            }

            console.log(`✅ Created ${count} tasks successfully`);
            return { success: true, count };
        } catch (error) {
            console.error('Failed to create tasks:', error);
            throw error;
        }
    }

    @Process('expire-tasks')
    async handleExpireTasks(job: Job) {
        console.log('⏰ Checking for expired tasks...');

        // TODO: Find and expire tasks past deadline

        return { success: true };
    }
}
