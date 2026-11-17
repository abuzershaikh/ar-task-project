import { BadRequestException, Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { promises as fs } from 'fs';
import * as path from 'path';
import { FirebaseAdminService } from './firebase-admin.service';
import { RedisCacheService } from './redis-cache.service';
import { workerDeletionKey } from './worker-deletion-guard';
import { UserRole } from '../database/entities/user.entity';

@Injectable()
export class WorkerDeletionService {
    constructor(
        private readonly db: DataSource,
        private readonly firebase: FirebaseAdminService,
        private readonly cache: RedisCacheService,
    ) {}

    async deleteWorker(targetId: string, resolved: { worker: any; user: any; searchIds: string[] }): Promise<void> {
        const { worker, user } = resolved;
        if (user && user.role !== UserRole.WORKER) {
            throw new BadRequestException('Only worker accounts can be deleted here');
        }
        const workerRows = await this.db.query(
            'SELECT id, user_id FROM workers WHERE id = ? OR user_id = ?',
            [targetId, user?.id || worker?.userId || targetId],
        );
        const keys: string[] = [...new Set<string>([
            targetId, ...resolved.searchIds, user?.id, user?.email,
            worker?.id, worker?.userId, user?.metadata?.firebaseUid,
            ...workerRows.flatMap((w: any) => [w.id, w.user_id]),
        ].filter(Boolean))];
        const initialSlots = keys.map(() => '?').join(',');
        const accounts = await this.db.query(`SELECT id, role FROM users WHERE id IN (${initialSlots})`, keys);
        if (accounts.some((account: any) => account.role !== UserRole.WORKER)) {
            throw new BadRequestException('Cannot delete a non-worker account');
        }

        // Persist deletion intent first. A failed external cleanup stays retryable,
        // and old mobile requests cannot recreate the account during cleanup.
        for (const key of keys) {
            await this.db.query('INSERT IGNORE INTO deleted_worker_accounts (identity_hash) VALUES (?)', [workerDeletionKey(key)]);
        }

        await this.deleteFirebaseAccount(keys, user?.email || keys.find((key) => key.includes('@')));
        const slots = keys.map(() => '?').join(',');
        const files = await this.db.query(`SELECT file_name FROM files WHERE uploaded_by IN (${slots})`, keys);
        const media = await this.db.query(
            `SELECT media_url FROM support_messages WHERE worker_id IN (${slots}) OR conversation_id IN
             (SELECT id FROM support_conversations WHERE worker_id IN (${slots}))`, [...keys, ...keys],
        );

        for (const file of files) {
            await this.unlinkOwnedFile(path.resolve(process.cwd(), 'uploads'), file.file_name);
        }
        // Support media lives in its own service directory on the same VPS.
        const supportRoot = process.env.SUPPORT_CHAT_UPLOAD_DIR || path.resolve(process.cwd(), '../support-chat-engine/uploads');
        for (const mediaUrl of new Set<string>(media.map((message: any) => message.media_url).filter(Boolean))) {
            // Admin bulk messages can reuse one attachment across many workers.
            // Remove the target's rows, but retain a file another chat still uses.
            const shared = await this.db.query(`SELECT id FROM support_messages WHERE media_url = ?
                AND worker_id NOT IN (${slots}) AND conversation_id NOT IN
                (SELECT id FROM support_conversations WHERE worker_id IN (${slots})) LIMIT 1`, [mediaUrl, ...keys, ...keys]);
            if (shared.length) continue;
            try {
                const url = new URL(mediaUrl, 'https://reviewsgateway.in');
                const fileName = url.pathname.split('/').pop();
                if (url.hostname === 'reviewsgateway.in' && url.pathname.startsWith('/support-chat/uploads/') && fileName) {
                    await this.unlinkOwnedFile(supportRoot, decodeURIComponent(fileName));
                }
            } catch {
                // Ignore malformed or external URLs during media cleanup
            }
        }

        // All SQL changes use one connection and roll back together. Foreign keys
        // remain enabled, including on pooled connections used by other requests.
        await this.db.transaction(async (manager) => {
            const lockedAccounts = await manager.query(`SELECT id, role FROM users WHERE id IN (${slots}) FOR UPDATE`, keys);
            if (lockedAccounts.some((account: any) => account.role !== UserRole.WORKER)) {
                throw new BadRequestException('Cannot delete a non-worker account');
            }
            const legacyColumns = await manager.query(`SELECT COLUMN_NAME FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'tasks' AND COLUMN_NAME = 'worker_id'`);
            const hasLegacyWorkerId = legacyColumns.length > 0;
            const ownership = hasLegacyWorkerId
                ? `(assigned_to IN (${slots}) OR (assigned_to IS NULL AND worker_id IN (${slots})))`
                : `assigned_to IN (${slots})`;
            const ownershipParams = hasLegacyWorkerId ? [...keys, ...keys] : keys;
            const tasks = await manager.query(
                `SELECT id, order_id, order_unit_id FROM tasks WHERE ${ownership} FOR UPDATE`, ownershipParams,
            );

            // Tasks are shared buyer order slots. Erase the worker's history and
            // return their slots to availability without removing another worker's work.
            await manager.query(`UPDATE tasks SET status = 'ACTIVE', assigned_to = NULL,
                assigned_at = NULL, accepted_at = NULL, started_at = NULL, submitted_at = NULL,
                completed_at = NULL, deadline = NULL, attempt_count = 0, metadata = NULL
                ${hasLegacyWorkerId ? ', worker_id = NULL' : ''}
                WHERE ${ownership}`, ownershipParams);
            if (hasLegacyWorkerId) {
                // Clear a stale legacy alias without resetting a task now owned by someone else.
                await manager.query(`UPDATE tasks SET worker_id = NULL WHERE worker_id IN (${slots})`, keys);
            }
            for (const task of tasks) {
                if (task.order_unit_id) {
                    await manager.query(`UPDATE order_units SET status = 'PENDING' WHERE id = ? AND NOT EXISTS
                        (SELECT 1 FROM tasks WHERE order_unit_id = ? AND assigned_to IS NOT NULL
                         AND UPPER(status) IN ('ASSIGNED','ACCEPTED','STARTED','IN_PROGRESS','SUBMITTED','COMPLETED','APPROVED'))`,
                    [task.order_unit_id, task.order_unit_id]);
                }
            }

            for (const table of ['task_submissions', 'task_assignments', 'campaign_worker_participation',
                'worker_scores', 'kyc_profiles', 'earnings', 'withdrawals', 'payment_methods', 'ratings']) {
                await manager.query(`DELETE FROM ${table} WHERE worker_id IN (${slots})`, keys);
            }
            await manager.query(`DELETE FROM worker_completed_identities WHERE worker_key IN (${slots})`, keys);
            await manager.query(`DELETE FROM support_messages WHERE worker_id IN (${slots}) OR conversation_id IN
                (SELECT id FROM support_conversations WHERE worker_id IN (${slots}))`, [...keys, ...keys]);
            await manager.query(`DELETE FROM support_conversations WHERE worker_id IN (${slots})`, keys);
            await manager.query(`DELETE FROM notifications WHERE user_id IN (${slots})`, keys);
            await manager.query(`DELETE FROM files WHERE uploaded_by IN (${slots})`, keys);
            await manager.query(`DELETE FROM wallet_transactions WHERE wallet_id IN
                (SELECT id FROM wallets WHERE user_id IN (${slots}))`, keys);
            await manager.query(`DELETE FROM wallets WHERE user_id IN (${slots})`, keys);
            await manager.query(`DELETE FROM audit_logs WHERE actor_id IN (${slots}) OR entity_id IN (${slots})`, [...keys, ...keys]);
            await manager.query(`DELETE FROM workers WHERE id IN (${slots}) OR user_id IN (${slots})`, [...keys, ...keys]);
            await manager.query(`DELETE FROM users WHERE id IN (${slots}) AND role = 'WORKER'`, keys);

            for (const orderId of [...new Set(tasks.map((t: any) => t.order_id))]) {
                await manager.query(`UPDATE orders o SET tasks_completed =
                    (SELECT COUNT(*) FROM tasks t WHERE t.order_id = o.id AND UPPER(t.status) IN ('COMPLETED','APPROVED')),
                    status = CASE WHEN UPPER(o.status) = 'COMPLETED' AND
                    (SELECT COUNT(*) FROM tasks t WHERE t.order_id = o.id AND UPPER(t.status) IN ('COMPLETED','APPROVED'))
                    < o.total_tasks_required THEN 'ACTIVE' ELSE o.status END WHERE o.id = ?`, [orderId]);
            }
        });
        await Promise.all(keys.map((key) => this.cache.invalidateWorker(key).catch(() => {})));
    }

    private async deleteFirebaseAccount(keys: string[], email?: string): Promise<void> {
        const auth = this.firebase.auth;
        const firestore = this.firebase.firestore;
        const uids = new Set<string>();
        const ignoreMissingUser = (error: any) => {
            if (
                error.code !== 'auth/user-not-found' &&
                error.code !== 'auth/invalid-uid' &&
                error.code !== 'auth/invalid-email' &&
                error.code !== 'auth/invalid-argument'
            ) {
                throw error;
            }
            return null;
        };

        const nonEmailKeys = keys.filter((value) => value && !value.includes('@'));
        const trimmedEmail = email?.trim();

        const [emailAccount, keyAccounts, firestoreMatches] = await Promise.all([
            trimmedEmail ? auth.getUserByEmail(trimmedEmail).catch(ignoreMissingUser) : Promise.resolve(null),
            Promise.all(nonEmailKeys.map((key) => auth.getUser(key).catch(ignoreMissingUser))),
            trimmedEmail
                ? firestore.collection('users').where('email', '==', trimmedEmail).get().catch(() => ({ docs: [] }))
                : Promise.resolve({ docs: [] }),
        ]);

        if (emailAccount) uids.add(emailAccount.uid);
        for (const account of keyAccounts) {
            if (account) uids.add(account.uid);
        }

        const docs = new Map<string, any>();
        for (const key of new Set([...keys, ...uids])) {
            if (!key || key.includes('/')) continue;
            const doc = firestore.collection('users').doc(key);
            docs.set(doc.path, doc);
        }

        if (firestoreMatches.docs.length > 0) {
            const matchAccounts = await Promise.all(
                firestoreMatches.docs.map((doc: any) => {
                    docs.set(doc.ref.path, doc.ref);
                    return auth.getUser(doc.id).catch(ignoreMissingUser);
                }),
            );
            for (const account of matchAccounts) {
                if (account) uids.add(account.uid);
            }
        }

        // Capture every discovered UID before removing its authentication record.
        // Old clients may identify themselves by UID instead of email.
        await Promise.all(
            [...uids].map((uid) => {
                if (!keys.includes(uid)) keys.push(uid);
                return this.db.query('INSERT IGNORE INTO deleted_worker_accounts (identity_hash) VALUES (?)', [workerDeletionKey(uid)]);
            }),
        );

        // Revocation/deletion failures propagate; the UI must never claim success.
        await Promise.all(
            [...uids].map(async (uid) => {
                await auth.revokeRefreshTokens(uid).catch(ignoreMissingUser);
                await auth.deleteUser(uid).catch(ignoreMissingUser);
                const doc = firestore.collection('users').doc(uid);
                docs.set(doc.path, doc);
            }),
        );

        await Promise.all([...docs.values()].map((doc) => firestore.recursiveDelete(doc)));
    }

    private async unlinkOwnedFile(root: string, fileName?: string): Promise<void> {
        if (!fileName) return;
        const base = path.resolve(root);
        const target = path.resolve(base, fileName);
        if (path.dirname(target) !== base || fileName !== path.basename(fileName)) {
            throw new BadRequestException('Invalid worker upload path');
        }
        try {
            await fs.unlink(target);
        } catch (error) {
            if (error.code !== 'ENOENT') throw error;
        }
    }
}
