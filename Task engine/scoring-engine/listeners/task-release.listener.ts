import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { WorkerRepository } from '../../shared/database/repositories/worker.repository';
import { ScoringEngineService } from '../scoring.service';

@Injectable()
export class TaskReleaseListener {
    private readonly logger = new Logger(TaskReleaseListener.name);

    constructor(
        private readonly workerRepo: WorkerRepository,
        private readonly scoringEngine: ScoringEngineService
    ) {}

    @OnEvent('worker.task_released')
    async handleTaskReleasedEvent(payload: { taskId: string; workerId: string; reason: string; timestamp: string }) {
        this.logger.log(`Received worker.task_released event for worker ${payload.workerId} on task ${payload.taskId}`);
        
        try {
            const worker = await this.workerRepo.findWorker(payload.workerId);
            if (worker) {
                // Increment dropped tasks / rejected tasks to penalize the worker score
                const currentRejected = Number(worker.totalTasksRejected || 0);
                await this.workerRepo.incrementTasksRejected(worker.id);
                this.logger.log(`Penalized worker ${payload.workerId} for dropping task ${payload.taskId}. Total dropped/rejected: ${currentRejected + 1}`);

                // Immediately recalculate & persist updated score
                await this.scoringEngine.calculateWorkerScore(worker.id);
            }
        } catch (error) {
            this.logger.error(`Error processing task release penalty for worker ${payload.workerId}`, error.stack);
        }
    }

    @OnEvent('worker.score.recalculate')
    async handleWorkerScoreRecalculate(payload: string | { workerId?: string; id?: string }) {
        const workerId = typeof payload === 'string' ? payload : (payload?.workerId || payload?.id);
        if (!workerId) {
            this.logger.warn(`Received invalid worker.score.recalculate event payload: ${JSON.stringify(payload)}`);
            return;
        }

        this.logger.log(`Received worker.score.recalculate event for worker ${workerId}`);
        try {
            await this.scoringEngine.calculateWorkerScore(workerId);
            this.logger.log(`Successfully recalculated and persisted score for worker ${workerId}`);
        } catch (error) {
            this.logger.error(`Failed to recalculate score for worker ${workerId}`, error.stack);
        }
    }
}
