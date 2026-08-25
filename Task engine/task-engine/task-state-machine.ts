import { Injectable } from '@nestjs/common';
import { TaskContext } from './types/task-context.interface';
import { TaskStatus } from './types/task-status.enum';

export interface StateTransition {
    from: TaskStatus;
    to: TaskStatus;
    conditions?: string[];
    sideEffects?: string[];
}

@Injectable()
export class TaskStateMachine {
    private static readonly transitions: Map<TaskStatus, TaskStatus[]> = new Map([
        [TaskStatus.DRAFT, [TaskStatus.ACTIVE, TaskStatus.CANCELLED]],
        [TaskStatus.ACTIVE, [TaskStatus.ASSIGNED, TaskStatus.ACCEPTED, TaskStatus.EXPIRED, TaskStatus.CANCELLED]],
        [TaskStatus.ASSIGNED, [TaskStatus.ACCEPTED, TaskStatus.ACTIVE, TaskStatus.EXPIRED, TaskStatus.CANCELLED]],
        [TaskStatus.ACCEPTED, [TaskStatus.IN_PROGRESS, TaskStatus.ACTIVE, TaskStatus.EXPIRED, TaskStatus.CANCELLED]],
        [TaskStatus.IN_PROGRESS, [TaskStatus.SUBMITTED, TaskStatus.ACTIVE, TaskStatus.EXPIRED, TaskStatus.CANCELLED]],
        [TaskStatus.SUBMITTED, [TaskStatus.UNDER_REVIEW, TaskStatus.IN_PROGRESS, TaskStatus.ACTIVE, TaskStatus.EXPIRED]],
        [TaskStatus.UNDER_REVIEW, [TaskStatus.APPROVED, TaskStatus.REJECTED, TaskStatus.IN_PROGRESS]],
        [TaskStatus.REJECTED, [TaskStatus.SUBMITTED, TaskStatus.IN_PROGRESS, TaskStatus.ACTIVE, TaskStatus.ASSIGNED, TaskStatus.FAILED, TaskStatus.APPROVED]], // SUBMITTED & IN_PROGRESS added for worker resubmission & Admin Override
        [TaskStatus.APPROVED, []],
        [TaskStatus.CANCELLED, []],
        [TaskStatus.EXPIRED, []],
        [TaskStatus.FAILED, []],
    ]);

    canTransition(from: TaskStatus | string, to: TaskStatus | string): boolean {
        return TaskStateMachine.canTransition(from, to);
    }

    validateTransition(context: TaskContext): void {
        TaskStateMachine.validateTransition(context.currentStatus, context.targetStatus);
    }

    getNextStates(status: TaskStatus | string): TaskStatus[] {
        return TaskStateMachine.getAllowedTransitions(status);
    }

    isTerminalState(status: TaskStatus | string): boolean {
        return TaskStateMachine.isTerminalState(status);
    }

    static canTransition(from: TaskStatus | string, to: TaskStatus | string): boolean {
        return this.getAllowedTransitions(from).includes(to as TaskStatus);
    }

    static getAllowedTransitions(from: TaskStatus | string): TaskStatus[] {
        return this.transitions.get(from as TaskStatus) || [];
    }

    static isTerminalState(status: TaskStatus | string): boolean {
        return this.getAllowedTransitions(status).length === 0;
    }

    static validateTransition(from: TaskStatus | string, to: TaskStatus | string): void {
        if (!this.canTransition(from, to)) {
            throw new Error(
                `Invalid state transition: ${from} -> ${to}. Allowed transitions: ${this.getAllowedTransitions(from).join(', ')}`,
            );
        }
    }

    static getTransitionPath(from: TaskStatus | string, to: TaskStatus | string): TaskStatus[] | null {
        if (from === to) {
            return [from as TaskStatus];
        }

        if (this.canTransition(from, to)) {
            return [from as TaskStatus, to as TaskStatus];
        }

        const visited = new Set<TaskStatus>();
        const queue: { status: TaskStatus; path: TaskStatus[] }[] = [{ status: from as TaskStatus, path: [from as TaskStatus] }];

        while (queue.length > 0) {
            const { status, path } = queue.shift()!;

            if (status === to) {
                return path;
            }

            if (visited.has(status)) {
                continue;
            }

            visited.add(status);

            for (const nextState of this.getAllowedTransitions(status)) {
                if (!visited.has(nextState)) {
                    queue.push({ status: nextState, path: [...path, nextState] });
                }
            }
        }

        return null;
    }
}
