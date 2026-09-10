import { BadRequestException, Injectable } from '@nestjs/common';
import { TaskStateMachine } from './state-machine/task-state-machine';
import { TaskContext } from './types/task-context.interface';
import { TaskStatus } from './types/task-status.enum';

@Injectable()
export class TaskValidationService {
    constructor(private readonly stateMachine: TaskStateMachine) {}

    validateTransition(context: TaskContext): void {
        this.stateMachine.validateTransition(context);
    }

    canTransition(from: TaskStatus, to: TaskStatus): boolean {
        return this.stateMachine.canTransition(from, to);
    }

    ensureWorkerOwnership(task: { assignedTo?: string | null }, workerId: string, workerEmail?: string, allIds?: string[]): void {
        if (!task.assignedTo) {
            throw new BadRequestException('Task is not assigned to any worker');
        }
        const assign = (task.assignedTo || '').toLowerCase().trim();
        const wId = (workerId || '').toLowerCase().trim();
        const wEmail = (workerEmail || '').toLowerCase().trim();

        if (allIds && Array.isArray(allIds) && allIds.length > 0) {
            const normalizedIds = allIds.map((id) => (id || '').toLowerCase().trim()).filter(Boolean);
            if (normalizedIds.includes(assign)) {
                return;
            }
        }

        if (assign !== wId && (!wEmail || assign !== wEmail)) {
            throw new BadRequestException('Task is assigned to another worker');
        }
    }

    ensureTaskAssignable(task: { status: string; assignedTo?: string | null }): void {
        if (task.assignedTo) {
            throw new BadRequestException('Task is already assigned');
        }

        if (task.status !== TaskStatus.ACTIVE) {
            throw new BadRequestException('Task is not available for assignment');
        }
    }
}
