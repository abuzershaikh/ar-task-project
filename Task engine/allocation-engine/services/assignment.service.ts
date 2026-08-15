import { Injectable, Inject, forwardRef, BadRequestException } from '@nestjs/common';
import { TaskRepository } from '../../shared/database/repositories/task.repository';
import { TaskEngineService } from '../../task-engine/task-engine.service';
import { NotificationEngineService } from '../../notification-engine/notification.service';
import { AllocationRequest, AllocationResult } from '../types';

/**
 * Tasks ko workers ko assign karta hai
 */
@Injectable()
export class AssignmentService {
    constructor(
        private readonly taskRepo: TaskRepository,
        private readonly notificationEngine: NotificationEngineService,
        @Inject(forwardRef(() => TaskEngineService))
        private readonly taskEngine: TaskEngineService,
    ) { }

    async assign(request: AllocationRequest): Promise<AllocationResult> {
        const { taskIds, workerIds, pairs, strategy } = request;

        const targetPairs: Array<{ taskId: string; workerId: string }> = pairs || [];
        if (!pairs) {
            if (taskIds.length !== workerIds.length) {
                throw new BadRequestException('Task and Worker array length mismatch. Explicit pairs are required.');
            }
            const count = taskIds.length;
            for (let i = 0; i < count; i++) {
                targetPairs.push({ taskId: taskIds[i], workerId: workerIds[i] });
            }
        }

        const assignments: any[] = [];
        let successCount = 0;
        let failedCount = 0;

        for (const pair of targetPairs) {
            try {
                const task = await this.taskRepo.findById(pair.taskId);

                if (task && !task.assignedTo) {
                    // Check capacity at the very last moment to reduce race window
                    const activeCounts = await this.taskRepo.getWorkerActiveTaskCounts([pair.workerId]);
                    const currentActive = activeCounts.get(pair.workerId) || 0;
                    if (currentActive >= 5) { // MAX_CONCURRENT_TASKS
                        console.warn(`Worker ${pair.workerId} reached maximum capacity. Aborting assignment for task ${pair.taskId}`);
                        failedCount++;
                        continue;
                    }

                    await this.taskEngine.assignTask({
                        taskId: pair.taskId,
                        workerId: pair.workerId,
                        actorId: 'system',
                    });

                    // Send Notification to Worker
                    await this.notificationEngine.sendNotification(
                        pair.workerId,
                        'A new task has been assigned to you! Check your task feed to start.',
                        'TASK_ASSIGNED',
                        { taskId: pair.taskId }
                    );

                    assignments.push({
                        taskId: pair.taskId,
                        workerId: pair.workerId,
                        assignedAt: new Date(),
                    });

                    successCount++;
                } else {
                    failedCount++;
                }
            } catch (error) {
                failedCount++;
                console.error(`Failed to assign task ${pair.taskId} to worker ${pair.workerId}:`, error.message || error);
            }
        }

        return {
            assignments,
            successCount,
            failedCount,
            timestamp: new Date(),
        };
    }
}
