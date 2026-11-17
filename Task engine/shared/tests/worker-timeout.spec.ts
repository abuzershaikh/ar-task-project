import { executionDeadline, WORKER_EXECUTION_TIMEOUT_MS } from '../common/utils/worker-execution-deadline';
import { DeadlineMonitorService } from '../engines/reallocation-engine/services/deadline-monitor.service';
import { TaskReleaseService } from '../engines/reallocation-engine/services/task-release.service';
import { ReleaseReason } from '../engines/reallocation-engine/types/reallocation.types';
import { Task } from '../database/entities/task.entity';
import { TaskAssignment } from '../database/entities/task-assignment.entity';
import { CampaignWorkerParticipation } from '../database/entities/campaign-worker-participation.entity';
import { TaskCommandService } from '../../task-engine/handlers/task-command.service';

describe('30-minute worker task window', () => {
    const now = new Date('2026-11-12T10:00:00Z');
    const acceptedAt = new Date(now.getTime() - WORKER_EXECUTION_TIMEOUT_MS);
    beforeEach(() => { jest.useFakeTimers(); jest.setSystemTime(now); });
    afterEach(() => jest.useRealTimers());

    it('caps legacy two-hour deadlines at 30 minutes from acceptance, not start', () => {
        expect(executionDeadline({ acceptedAt, startedAt: now, deadline: new Date(now.getTime() + 90 * 60000) })).toEqual(now);
    });

    it('returns expired accepted work to the pool rather than reserving it to one more worker', async () => {
        const tasks = [
            { id: 'expired', status: 'in_progress', assignedTo: 'worker-a', acceptedAt, deadline: new Date(now.getTime() + 90 * 60000) },
            { id: 'fresh', status: 'accepted', assignedTo: 'worker-b', acceptedAt: new Date(now.getTime() - 29 * 60000) },
            { id: 'proof', status: 'under_review', assignedTo: 'worker-c', acceptedAt },
            { id: 'changes', status: 'in_progress', assignedTo: 'worker-d', acceptedAt, submittedAt: acceptedAt },
        ];
        const release = { releaseWorkerFromTask: jest.fn().mockResolvedValue(true) };
        const reassign = { reassignTaskToNewWorker: jest.fn() };
        const monitor = new DeadlineMonitorService({ findAssignedTasks: async () => tasks } as any, null as any, null as any, release as any, reassign as any);
        const result = await monitor.processFullTimeouts();
        expect(result.expiredCount).toBe(1);
        expect(release.releaseWorkerFromTask).toHaveBeenCalledWith(expect.objectContaining({ taskId: 'expired' }));
        expect(reassign.reassignTaskToNewWorker).not.toHaveBeenCalled();
    });

    function fixture(overrides = {}) {
        const task: any = { id: 'task', orderId: 'order', status: 'in_progress', assignedTo: 'worker-a', acceptedAt, ...overrides };
        const assignment: any = { id: 'attempt', status: 'STARTED' };
        const participation: any = { id: 'participation', expiredCount: 0 };
        const manager = {
            findOne: jest.fn(async (entity) => entity === Task ? task : entity === TaskAssignment ? assignment : participation),
            save: jest.fn(async (entity) => entity), create: jest.fn((_, data) => data),
        };
        const db = { transaction: jest.fn(async (callback) => callback(manager)) };
        const events = { emit: jest.fn() };
        return { task, assignment, participation, manager, db, events,
            release: new TaskReleaseService(null as any, null as any, null as any, events as any, db as any) };
    }
    const request = { taskId: 'task', workerId: 'worker-a', campaignId: 'order', reason: ReleaseReason.WORKER_TIMEOUT };

    it('atomically releases the old assignment, preserves exclusion, and opens the same task', async () => {
        const f = fixture();
        expect(await f.release.releaseWorkerFromTask(request)).toBe(true);
        expect(f.manager.findOne).toHaveBeenCalledWith(Task, expect.objectContaining({ lock: { mode: 'pessimistic_write' } }));
        expect(f.task.status).toBe('active');
        expect(f.task.assignedTo).toBeNull();
        expect(f.assignment.status).toBe('EXPIRED');
        expect(f.participation.status).toBe('EXPIRED');
        expect(f.events.emit).toHaveBeenCalledTimes(1);
        expect(await f.release.releaseWorkerFromTask(request)).toBe(false);
        expect(f.events.emit).toHaveBeenCalledTimes(1);
    });

    it.each([
        { status: 'under_review', submittedAt: now },
        { status: 'submitted' }, { status: 'approved' }, { status: 'completed' },
        { assignedTo: 'worker-b' }, { assignedTo: null },
        { acceptedAt: new Date(now.getTime() - 29 * 60000) },
    ])('rechecks current ownership/status/deadline under the lock: %s', async (overrides) => {
        const f = fixture(overrides);
        expect(await f.release.releaseWorkerFromTask(request)).toBe(false);
        expect(f.manager.save).not.toHaveBeenCalled();
        expect(f.events.emit).not.toHaveBeenCalled();
    });

    it('rejects a late proof submission before recording submission state', async () => {
        const f = fixture();
        const command: any = new TaskCommandService(f.db as any, null as any, null as any, null as any,
            { ensureWorkerOwnership: jest.fn() } as any, null as any);
        command.resolveWorkerIdentifiers = async () => ({ allIds: ['worker-a'] });
        await expect(command.submitTask({ taskId: 'task', workerId: 'worker-a', data: {} })).rejects.toThrow('30-minute');
        expect(f.manager.save).not.toHaveBeenCalled();
    });
});
