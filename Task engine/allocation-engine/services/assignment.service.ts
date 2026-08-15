import { Injectable, Inject, forwardRef } from '@nestjs/common';
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
        const { taskIds, workerIds, strategy } = request;

        const assignments: any[] = [];
        let successCount = 0;
        let failedCount = 0;

        // Sequential assignment
        for (let i = 0; i < taskIds.length && i < workerIds.length; i++) {
            try {
                const task = await this.taskRepo.findById(taskIds[i]);

                if (task && !task.assignedTo) {
                    await this.taskEngine.assignTask({
                        taskId: taskIds[i],
                        workerId: workerIds[i],
                        actorId: 'system',
                    });

                    // Send Notification to Worker
                    await this.notificationEngine.sendNotification(
                        workerIds[i],
                        'A new task has been assigned to you! Check your task feed to start.',
                        'TASK_ASSIGNED',
                        { taskId: taskIds[i] }
                    );

                    assignments.push({
                        taskId: taskIds[i],
                        workerId: workerIds[i],
                        assignedAt: new Date(),
                    });

                    successCount++;
                } else {
                    failedCount++;
                }
            } catch (error) {
                failedCount++;
                console.error(`Failed to assign task ${taskIds[i]}:`, error.message || error);
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
