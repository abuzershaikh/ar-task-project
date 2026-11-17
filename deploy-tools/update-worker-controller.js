const fs = require('fs');
const path = require('path');

const filePath = path.resolve(__dirname, '../Task engine/apps/api/controllers/admin/worker-management.controller.ts');
let content = fs.readFileSync(filePath, 'utf8');

const targetMethodStart = '    private async performCascadeWorkerDelete(targetId: string): Promise<boolean> {';
const startIndex = content.indexOf(targetMethodStart);
if (startIndex === -1) {
    console.error('Target method start not found!');
    process.exit(1);
}

// Find the end of the class (before the last closing brace)
const lastBraceIndex = content.lastIndexOf('}');
if (lastBraceIndex === -1) {
    console.error('Closing brace not found!');
    process.exit(1);
}

const replacementCode = `    private async performCascadeWorkerDelete(targetId: string): Promise<boolean> {
        const { worker, user, searchIds } = await this.resolveWorkerAndUser(targetId);

        let userId = user?.id || worker?.userId;
        let workerId = worker?.id;

        // Also query workers table directly to catch any worker row by user_id or id
        try {
            const extraWorkerRows = await this.dataSource.query(
                'SELECT id, user_id FROM workers WHERE id = ? OR user_id = ?;',
                [targetId, userId || targetId]
            );
            for (const wr of extraWorkerRows) {
                if (wr.id) searchIds.push(wr.id);
                if (wr.user_id) {
                    searchIds.push(wr.user_id);
                    if (!userId) userId = wr.user_id;
                }
            }
        } catch (_) {}

        if (userId) {
            try {
                const extraUser = await this.userRepo.findById(userId);
                if (extraUser?.email) {
                    searchIds.push(extraUser.email);
                    searchIds.push(extraUser.email.toLowerCase().trim());
                }
            } catch (_) {}
        }

        const uniqueKeys = Array.from(new Set(searchIds.filter(Boolean) as string[]));

        if (uniqueKeys.length === 0) {
            return true; // Already deleted, consider success
        }

        // Safety check: protect Super Admins & Admins
        if (userId) {
            const userToCheck = user || (await this.userRepo.findById(userId));
            if (userToCheck && (userToCheck.role === UserRole.ADMIN || userToCheck.role === UserRole.SUPER_ADMIN)) {
                return false;
            }
        }

        const placeholders = uniqueKeys.map(() => '?').join(', ');

        await this.dataSource.query('SET FOREIGN_KEY_CHECKS = 0;');
        try {
            // 1. Reset / Wipe ALL tasks associated with this worker to 0
            // Find all tasks assigned to ANY of the worker/user keys
            const assignedTasks = await this.dataSource.query(
                \`SELECT id, order_id, order_unit_id, status FROM tasks WHERE assigned_to IN (\${placeholders});\`,
                uniqueKeys
            );

            if (assignedTasks && assignedTasks.length > 0) {
                // Return any linked order units back to PENDING so orders can be cleanly fulfilled
                const orderUnitIds = Array.from(new Set(assignedTasks.map((t: any) => t.order_unit_id).filter(Boolean)));
                if (orderUnitIds.length > 0) {
                    const unitPlaceholders = orderUnitIds.map(() => '?').join(', ');
                    await this.dataSource.query(
                        \`UPDATE order_units SET status = 'PENDING' WHERE id IN (\${unitPlaceholders});\`,
                        orderUnitIds
                    );
                }

                // Reset all these tasks back to ACTIVE with assigned_to = NULL, all timestamps cleared (total tasks becomes 0)
                await this.dataSource.query(
                    \`UPDATE tasks SET
                        status = 'ACTIVE',
                        assigned_to = NULL,
                        assigned_at = NULL,
                        accepted_at = NULL,
                        started_at = NULL,
                        submitted_at = NULL,
                        completed_at = NULL,
                        deadline = NULL,
                        metadata = NULL
                    WHERE assigned_to IN (\${placeholders});\`,
                    uniqueKeys
                );

                // Recalculate tasks_completed for all affected orders
                const affectedOrderIds = Array.from(new Set(assignedTasks.map((t: any) => t.order_id).filter(Boolean)));
                for (const orderId of affectedOrderIds) {
                    await this.dataSource.query(
                        \`UPDATE orders o
                        SET tasks_completed = (
                            SELECT COUNT(*) FROM tasks t
                            WHERE t.order_id = o.id AND t.status IN ('COMPLETED', 'completed', 'APPROVED', 'approved')
                        ),
                        status = CASE
                            WHEN (
                                SELECT COUNT(*) FROM tasks t
                                WHERE t.order_id = o.id AND t.status IN ('COMPLETED', 'completed', 'APPROVED', 'approved')
                            ) < o.total_tasks_required AND o.status = 'COMPLETED' THEN 'ACTIVE'
                            ELSE o.status
                        END
                        WHERE o.id = ?;\`,
                        [orderId]
                    );
                }
            }

            // 2. Wipe task submissions
            await this.dataSource.query(\`DELETE FROM task_submissions WHERE worker_id IN (\${placeholders});\`, uniqueKeys);

            // 3. Wipe task assignments
            await this.dataSource.query(\`DELETE FROM task_assignments WHERE worker_id IN (\${placeholders});\`, uniqueKeys);

            // 4. Wipe worker completed identities (so task identity/history is completely wiped to 0)
            await this.dataSource.query(\`DELETE FROM worker_completed_identities WHERE worker_key IN (\${placeholders});\`, uniqueKeys);

            // 5. Wipe campaign participation
            await this.dataSource.query(\`DELETE FROM campaign_worker_participation WHERE worker_id IN (\${placeholders});\`, uniqueKeys);

            // 6. Wipe worker scores
            await this.dataSource.query(\`DELETE FROM worker_scores WHERE worker_id IN (\${placeholders});\`, uniqueKeys);

            // 7. Wipe KYC profiles
            await this.dataSource.query(\`DELETE FROM kyc_profiles WHERE worker_id IN (\${placeholders}) OR user_id IN (\${placeholders});\`, [...uniqueKeys, ...uniqueKeys]);

            // 8. Wipe earnings
            await this.dataSource.query(\`DELETE FROM earnings WHERE worker_id IN (\${placeholders});\`, uniqueKeys);

            // 9. Wipe withdrawals
            await this.dataSource.query(\`DELETE FROM withdrawals WHERE worker_id IN (\${placeholders});\`, uniqueKeys);

            // 10. Wipe ratings
            await this.dataSource.query(\`DELETE FROM ratings WHERE worker_id IN (\${placeholders});\`, uniqueKeys);

            // 11. Wipe support conversations and messages
            try {
                await this.dataSource.query(
                    \`DELETE FROM support_messages WHERE conversation_id IN (SELECT id FROM support_conversations WHERE worker_id IN (\${placeholders}));\`,
                    uniqueKeys
                );
                await this.dataSource.query(\`DELETE FROM support_conversations WHERE worker_id IN (\${placeholders});\`, uniqueKeys);
            } catch (_) {}

            // 12. Wipe notifications
            await this.dataSource.query(\`DELETE FROM notifications WHERE user_id IN (\${placeholders});\`, uniqueKeys);

            // 13. Wipe uploaded files
            await this.dataSource.query(\`DELETE FROM files WHERE uploaded_by IN (\${placeholders});\`, uniqueKeys);

            // 14. Wipe wallets and wallet transactions
            try {
                await this.dataSource.query(
                    \`DELETE FROM wallet_transactions WHERE wallet_id IN (SELECT id FROM wallets WHERE user_id IN (\${placeholders}));\`,
                    uniqueKeys
                );
                await this.dataSource.query(\`DELETE FROM wallets WHERE user_id IN (\${placeholders});\`, uniqueKeys);
            } catch (_) {}

            // 15. Wipe workers table
            await this.dataSource.query(\`DELETE FROM workers WHERE id IN (\${placeholders}) OR user_id IN (\${placeholders});\`, [...uniqueKeys, ...uniqueKeys]);

            // 16. Wipe users table
            if (userId) {
                await this.dataSource.query('DELETE FROM users WHERE id = ?;', [userId]);
            }
            await this.dataSource.query(\`DELETE FROM users WHERE id IN (\${placeholders});\`, uniqueKeys);

            // 17. Wipe Firebase Auth & Firestore account if configured
            if (this.firebaseAdminService) {
                try {
                    if (user?.metadata?.firebaseUid) {
                        await this.firebaseAdminService.auth.deleteUser(user.metadata.firebaseUid).catch(() => null);
                        await this.firebaseAdminService.firestore.collection('users').doc(user.metadata.firebaseUid).delete().catch(() => null);
                    }
                    if (user?.email) {
                        const fb = await this.firebaseAdminService.auth.getUserByEmail(user.email).catch(() => null);
                        if (fb?.uid) {
                            await this.firebaseAdminService.auth.deleteUser(fb.uid).catch(() => null);
                            await this.firebaseAdminService.firestore.collection('users').doc(fb.uid).delete().catch(() => null);
                        }
                    }
                } catch (_) {}
            }
        } finally {
            await this.dataSource.query('SET FOREIGN_KEY_CHECKS = 1;');
        }

        return true;
    }

    @Post('batch-delete')
    @ApiOperation({ summary: 'Batch delete multiple workers' })
    async batchDeleteWorkers(@Body() body: { ids?: string[]; workerIds?: string[] }) {
        const ids = body.ids || body.workerIds;
        if (!ids || !Array.isArray(ids) || ids.length === 0) {
            throw new BadRequestException('ids or workerIds array is required');
        }

        let deletedCount = 0;
        for (const id of ids) {
            const success = await this.performCascadeWorkerDelete(id);
            if (success) deletedCount++;
        }

        return {
            success: true,
            deletedCount,
            message: \`Successfully deleted and wiped \${deletedCount} worker(s) and reset all tasks to 0\`,
        };
    }

    @Delete(':id')
    @ApiOperation({ summary: 'Permanently delete worker and associated user' })
    async deleteWorker(@Param('id') workerId: string) {
        const success = await this.performCascadeWorkerDelete(workerId);
        if (!success) {
            throw new BadRequestException('Cannot delete administrator account');
        }

        return {
            success: true,
            message: \`Worker \${workerId} permanently deleted and all tasks wiped to 0\`,
        };
    }
}
`;

const updatedContent = content.substring(0, startIndex) + replacementCode;
fs.writeFileSync(filePath, updatedContent, 'utf8');
console.log('Worker management controller updated successfully!');

