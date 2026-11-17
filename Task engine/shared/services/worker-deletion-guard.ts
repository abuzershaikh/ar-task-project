import { ForbiddenException } from '@nestjs/common';
import { createHash } from 'crypto';

export function workerDeletionKey(identifier: string): string {
    const value = identifier.trim();
    return createHash('sha256').update(value.includes('@') ? value.toLowerCase() : value).digest('hex');
}

// Keep only one-way identifiers, never the deleted profile or financial data.
export async function assertWorkerAccountNotDeleted(
    db: { query: (sql: string, params?: any[]) => Promise<any> },
    ...identifiers: string[]
): Promise<void> {
    const keys = [...new Set(identifiers.filter(Boolean).map(workerDeletionKey))];
    if (!keys.length) return;
    const rows = await db.query(
        `SELECT identity_hash FROM deleted_worker_accounts WHERE identity_hash IN (${keys.map(() => '?').join(',')}) LIMIT 1`,
        keys,
    );
    if (rows.length) throw new ForbiddenException('This worker account has been permanently deleted.');
}
