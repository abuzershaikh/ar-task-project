import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { WorkerRepository } from '../../shared/database/repositories/worker.repository';
import { ScoringEngineService } from '../scoring.service';
import { PERFORMANCE_POINTS } from '../types/worker-score';

/**
 * Task Release / Rejection / Expiry Listener
 * 
 * PENALTY SYSTEM:
 * Task completed    → +1 performance point
 * Task rejected     → -3 penalty points + rejection count increment
 * Task expired      → -5 penalty points
 * Repeated reject   → temporary task cooldown (30m → 2h → 6h → 24h escalation)
 * 
 * After any point change, score is immediately recalculated.
 * Score always clamped 0 <= score <= 100.
 */
@Injectable()
export class TaskReleaseListener {
    private readonly logger = new Logger(TaskReleaseListener.name);

    constructor(
        private readonly workerRepo: WorkerRepository,
        private readonly scoringEngine: ScoringEngineService
    ) {}

    /**
     * Task rejected / dropped by worker
     * Penalty: -3 performance points + rejection increment + cooldown check
     */
    @OnEvent('worker.task_released')
    async handleTaskReleasedEvent(payload: { taskId: string; workerId: string; reason: string; timestamp: string }) {
        this.logger.log(`Received worker.task_released event for worker ${payload.workerId} on task ${payload.taskId}`);
        
        try {
            const worker = await this.workerRepo.findWorker(payload.workerId);
            if (worker) {
                // 1. Increment rejected tasks counter
                await this.workerRepo.incrementTasksRejected(worker.id);
                this.logger.log(`📛 Worker ${payload.workerId} rejected task ${payload.taskId}`);

                // 2. Apply rejection penalty: -3 performance points
                const newPoints = await this.workerRepo.applyPerformancePointChange(
                    worker.id,
                    PERFORMANCE_POINTS.TASK_REJECTED // -3
                );
                this.logger.log(`📉 Performance points updated for worker ${payload.workerId}: ${newPoints} (penalty: ${PERFORMANCE_POINTS.TASK_REJECTED})`);

                // 3. Check consecutive rejections → apply cooldown if needed
                const consecutiveRejections = await this.workerRepo.getConsecutiveRejectionCount(worker.id);
                if (consecutiveRejections >= 2) {
                    const cooldownUntil = await this.workerRepo.setTaskCooldown(worker.id, consecutiveRejections);
                    this.logger.warn(`⏸️ Worker ${payload.workerId} placed on task cooldown until ${cooldownUntil} (${consecutiveRejections} consecutive rejections)`);
                }

                // 4. Immediately recalculate & persist updated score
                await this.scoringEngine.calculateWorkerScore(worker.id);
                this.logger.log(`🔄 Score recalculated for worker ${payload.workerId} after rejection penalty`);
            }
        } catch (error) {
            this.logger.error(`Error processing task release penalty for worker ${payload.workerId}`, error.stack);
        }
    }

    /**
     * Task expired (worker didn't complete in time)
     * Penalty: -5 performance points (heavier than rejection)
     */
    @OnEvent('worker.task_expired')
    async handleTaskExpiredEvent(payload: { taskId: string; workerId: string; reason?: string }) {
        this.logger.log(`Received worker.task_expired event for worker ${payload.workerId} on task ${payload.taskId}`);

        try {
            const worker = await this.workerRepo.findWorker(payload.workerId);
            if (worker) {
                // 1. Increment rejected counter (expired = failed to deliver)
                await this.workerRepo.incrementTasksRejected(worker.id);

                // 2. Apply expiry penalty: -5 performance points (heavier)
                const newPoints = await this.workerRepo.applyPerformancePointChange(
                    worker.id,
                    PERFORMANCE_POINTS.TASK_EXPIRED // -5
                );
                this.logger.log(`📉 Performance points for worker ${payload.workerId}: ${newPoints} (expiry penalty: ${PERFORMANCE_POINTS.TASK_EXPIRED})`);

                // 3. Check consecutive issues → apply cooldown
                const consecutiveRejections = await this.workerRepo.getConsecutiveRejectionCount(worker.id);
                if (consecutiveRejections >= 2) {
                    const cooldownUntil = await this.workerRepo.setTaskCooldown(worker.id, consecutiveRejections);
                    this.logger.warn(`⏸️ Worker ${payload.workerId} placed on cooldown until ${cooldownUntil} after task expiry`);
                }

                // 4. Recalculate score
                await this.scoringEngine.calculateWorkerScore(worker.id);
            }
        } catch (error) {
            this.logger.error(`Error processing task expiry penalty for worker ${payload.workerId}`, error.stack);
        }
    }

    /**
     * Task completed successfully
     * Reward: +1 performance point
     */
    @OnEvent('worker.task_completed')
    async handleTaskCompletedEvent(payload: { taskId: string; workerId: string }) {
        this.logger.log(`Received worker.task_completed event for worker ${payload.workerId} on task ${payload.taskId}`);

        try {
            const worker = await this.workerRepo.findWorker(payload.workerId);
            if (worker) {
                // 1. Apply completion reward: +1 performance point
                const newPoints = await this.workerRepo.applyPerformancePointChange(
                    worker.id,
                    PERFORMANCE_POINTS.TASK_COMPLETED // +1
                );
                this.logger.log(`📈 Performance points for worker ${payload.workerId}: ${newPoints} (reward: +${PERFORMANCE_POINTS.TASK_COMPLETED})`);

                // 2. Clear any cooldown on successful completion (worker is being productive)
                if (this.workerRepo.isOnCooldown(worker)) {
                    await this.workerRepo.clearCooldown(worker.id);
                    this.logger.log(`✅ Cooldown cleared for worker ${payload.workerId} after successful task completion`);
                }

                // 3. Recalculate score with new performance points
                await this.scoringEngine.calculateWorkerScore(worker.id);
            }
        } catch (error) {
            this.logger.error(`Error processing task completion reward for worker ${payload.workerId}`, error.stack);
        }
    }

    /**
     * Score recalculation requested
     */
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
