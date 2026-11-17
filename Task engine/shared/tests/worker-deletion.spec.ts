import { WorkerDeletionService } from '../services/worker-deletion.service';
import { assertWorkerAccountNotDeleted, workerDeletionKey } from '../services/worker-deletion-guard';
import { AdminWorkerManagementController } from '../../apps/api/controllers/admin/worker-management.controller';
import { UserSyncService } from '../services/user-sync.service';

describe('Permanent worker deletion', () => {
    const missing = { code: 'auth/user-not-found' };
    let db: any;
    let manager: any;
    let firebase: any;
    let cache: any;
    let service: WorkerDeletionService;
    const resolved = {
        worker: { id: 'worker-1', userId: 'user-1' },
        user: { id: 'user-1', role: 'WORKER', email: 'worker@example.test' },
        searchIds: ['worker-1', 'user-1', 'worker@example.test'],
    };

    beforeEach(() => {
        manager = { query: jest.fn(async (sql: string) => {
            if (sql.startsWith('SELECT id, order_id')) return [{ id: 'task-1', order_id: 'order-1', order_unit_id: 'unit-1' }];
            return [];
        }) };
        db = { query: jest.fn().mockResolvedValue([]), transaction: jest.fn(async (fn) => fn(manager)) };
        const collection = {
            doc: jest.fn((id) => ({ path: `users/${id}` })),
            where: jest.fn(() => ({ get: jest.fn().mockResolvedValue({ docs: [] }) })),
        };
        firebase = {
            auth: {
                getUserByEmail: jest.fn().mockResolvedValue({ uid: 'firebase-1' }),
                getUser: jest.fn().mockRejectedValue(missing),
                revokeRefreshTokens: jest.fn().mockResolvedValue(undefined),
                deleteUser: jest.fn().mockResolvedValue(undefined),
            },
            firestore: { collection: jest.fn(() => collection), recursiveDelete: jest.fn().mockResolvedValue(undefined) },
        };
        cache = { invalidateWorker: jest.fn().mockResolvedValue(undefined) };
        service = new WorkerDeletionService(db, firebase, cache);
    });

    it('cleans all worker stores on one SQL transaction, releases tasks, and removes Firebase subcollections', async () => {
        await service.deleteWorker('worker-1', resolved);
        expect(db.transaction).toHaveBeenCalledTimes(1);
        const queries = manager.query.mock.calls.map(([sql]) => sql).join('\n');
        for (const table of ['task_submissions', 'task_assignments', 'worker_completed_identities',
            'kyc_profiles', 'payment_methods', 'earnings', 'withdrawals', 'ratings', 'worker_scores',
            'campaign_worker_participation', 'support_messages', 'support_conversations',
            'notifications', 'files', 'wallet_transactions', 'wallets', 'workers', 'users', 'audit_logs']) {
            expect(queries).toContain(`DELETE FROM ${table} `);
        }
        expect(queries).not.toContain('FOREIGN_KEY_CHECKS');
        expect(queries).not.toMatch(/kyc_profiles WHERE.*user_id/);
        expect(queries).toContain('attempt_count = 0');
        expect(queries).toContain('UPDATE orders');
        expect(firebase.auth.revokeRefreshTokens).toHaveBeenCalledWith('firebase-1');
        expect(firebase.auth.deleteUser).toHaveBeenCalledWith('firebase-1');
        expect(firebase.firestore.recursiveDelete).toHaveBeenCalledWith({ path: 'users/firebase-1' });
        expect(cache.invalidateWorker).toHaveBeenCalledWith('firebase-1');
        expect(db.query).toHaveBeenCalledWith(expect.stringContaining('INSERT IGNORE'), [workerDeletionKey('firebase-1')]);
    });

    it('does not delete any account or data when an administrator is selected', async () => {
        await expect(service.deleteWorker('worker-1', { ...resolved, user: { ...resolved.user, role: 'ADMIN' } })).rejects.toThrow('Only worker');
        expect(db.transaction).not.toHaveBeenCalled();
        expect(firebase.auth.deleteUser).not.toHaveBeenCalled();
        expect(db.query).not.toHaveBeenCalled();
    });

    it('propagates Firebase failures before SQL deletion instead of reporting success', async () => {
        firebase.auth.deleteUser.mockRejectedValue({ code: 'auth/internal-error' });
        await expect(service.deleteWorker('worker-1', resolved)).rejects.toEqual({ code: 'auth/internal-error' });
        expect(db.transaction).not.toHaveBeenCalled();
    });

    it('propagates SQL failure and never continues to delete the worker account', async () => {
        manager.query.mockImplementation(async (sql) => {
            if (sql.includes('DELETE FROM kyc_profiles')) throw new Error('DB unavailable');
            return [];
        });
        await expect(service.deleteWorker('worker-1', resolved)).rejects.toThrow('DB unavailable');
        expect(manager.query.mock.calls.some(([sql]) => sql.startsWith('DELETE FROM workers '))).toBe(false);
        expect(cache.invalidateWorker).not.toHaveBeenCalled();
    });

    it('allows retry when Firebase authentication has already been removed', async () => {
        firebase.auth.getUserByEmail.mockRejectedValue(missing);
        await expect(service.deleteWorker('worker-1', resolved)).resolves.toBeUndefined();
        expect(db.transaction).toHaveBeenCalledTimes(1);
    });

    it('also clears the legacy task worker_id without resetting another current owner', async () => {
        manager.query.mockImplementation(async (sql) => sql.includes('information_schema') ? [{ COLUMN_NAME: 'worker_id' }] : []);
        await service.deleteWorker('worker-1', resolved);
        const queries = manager.query.mock.calls.map(([sql]) => sql).join('\n');
        expect(queries).toContain('assigned_to IS NULL AND worker_id IN');
        expect(queries).toContain('UPDATE tasks SET worker_id = NULL WHERE worker_id IN');
    });

    it('blocks resync using a one-way identity, including case variations of email', async () => {
        db.query.mockResolvedValue([{ identity_hash: workerDeletionKey('worker@example.test') }]);
        expect(workerDeletionKey(' Worker@Example.Test ')).toBe(workerDeletionKey('worker@example.test'));
        await expect(assertWorkerAccountNotDeleted(db, 'Worker@Example.Test')).rejects.toThrow('permanently deleted');
        expect(db.query.mock.calls[0][1][0]).toHaveLength(64);
    });

    it('reports partial batch failures and deduplicates repeated IDs', async () => {
        const controller: any = Object.create(AdminWorkerManagementController.prototype);
        controller.performCascadeWorkerDelete = jest.fn(async (id) => {
            if (id === 'broken') throw new Error('failure');
            return true;
        });
        const response = await controller.batchDeleteWorkers({ ids: ['ok', 'broken', 'ok'] });
        expect(response.success).toBe(false);
        expect(response.deletedIds).toEqual(['ok']);
        expect(response.failedIds).toEqual(['broken']);
        expect(response.deletedCount).toBe(1);
    });

    it('rejects an old mobile identity before attempting user recreation', async () => {
        db.query.mockResolvedValue([{ identity_hash: 'deleted' }]);
        const users = { findByEmail: jest.fn() };
        const sync = new UserSyncService(users as any, {} as any, firebase, db);
        await expect(sync.ensureUserInMySQL('worker@example.test')).rejects.toThrow('permanently deleted');
        expect(users.findByEmail).not.toHaveBeenCalled();
    });

    it('does not recreate an orphan worker from a request already in flight when its parent is deleted', async () => {
        manager.query.mockResolvedValue([]);
        manager.getRepository = jest.fn();
        const sync: any = new UserSyncService({} as any, {} as any, firebase, db);
        await expect(sync.ensureWorkerRecord('user-1')).rejects.toThrow('no longer exists');
        expect(manager.query).toHaveBeenCalledWith(expect.stringContaining('FOR UPDATE'), ['user-1']);
        expect(manager.getRepository).not.toHaveBeenCalled();
    });

    it('rechecks deletion intent under the parent lock before creating a worker', async () => {
        manager.query.mockImplementation(async (sql) => sql.includes('deleted_worker_accounts')
            ? [{ identity_hash: 'deleted' }] : [{ id: 'user-1' }]);
        manager.getRepository = jest.fn();
        const sync: any = new UserSyncService({} as any, {} as any, firebase, db);
        await expect(sync.ensureWorkerRecord('user-1')).rejects.toThrow('permanently deleted');
        expect(manager.getRepository).not.toHaveBeenCalled();
    });
});
