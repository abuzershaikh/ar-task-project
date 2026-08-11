import { Injectable } from '@nestjs/common';
import { TaskRepository } from '../../shared/database/repositories/task.repository';
import { AllocationRequest, AllocationResult } from '../types';

/**
 * Tasks ko workers ko assign karta hai
 */
@Injectable()
export class AssignmentService {
    constructor(private readonly taskRepo: TaskRepository) { }

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
                    await this.taskRepo.update(taskIds[i], {
                        assignedTo: workerIds[i],
                        assignedAt: new Date(),
                        status: 'assigned',
                    });

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
                console.error(`Failed to assign task ${taskIds[i]}:`, error);
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
