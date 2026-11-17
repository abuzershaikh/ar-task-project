export const WORKER_EXECUTION_TIMEOUT_MS = 30 * 60 * 1000;

/** Anchor the execution window to acceptance; opening/starting the task cannot reset it. */
export function executionDeadline(task: {
    acceptedAt?: Date | string; startedAt?: Date | string;
    assignedAt?: Date | string; deadline?: Date | string; status?: string;
}): Date | null {
    const status = (task.status || '').toLowerCase();
    const accepted = task.acceptedAt || task.startedAt ||
        (['accepted', 'in_progress'].includes(status) ? task.assignedAt : null);
    const explicit = task.deadline ? new Date(task.deadline).getTime() : NaN;
    const cap = accepted ? new Date(accepted).getTime() + WORKER_EXECUTION_TIMEOUT_MS : NaN;
    const valid = [explicit, cap].filter(Number.isFinite);
    return valid.length ? new Date(Math.min(...valid)) : null;
}
