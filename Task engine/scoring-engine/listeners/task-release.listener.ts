import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { WorkerRepository } from '../../shared/database/repositories/worker.repository';

@Injectable()
export class TaskReleaseListener {
    private readonly logger = new Logger(TaskReleaseListener.name);

    constructor(private readonly workerRepo: WorkerRepository) {}

    @OnEvent('worker.task_released')
    async handleTaskReleasedEvent(payload: { taskId: string; workerId: string; reason: string; timestamp: string }) {
        this.logger.log(`Received worker.task_released event for worker ${payload.workerId} on task ${payload.taskId}`);
        
        try {
            const worker = await this.workerRepo.findById(payload.workerId) || await this.workerRepo.findByUserId(payload.workerId);
            if (worker) {
                // Increment dropped tasks / rejected tasks to penalize the worker score
                const currentRejected = worker.totalTasksRejected || 0;
                await this.workerRepo.update(worker.id, {
                    totalTasksRejected: currentRejected + 1,
                });
                this.logger.log(`Penalized worker ${payload.workerId} for dropping task ${payload.taskId}. Total dropped/rejected: ${currentRejected + 1}`);
            }
        } catch (error) {
            this.logger.error(`Error processing task release penalty for worker ${payload.workerId}`, error.stack);
        }
    }
}
