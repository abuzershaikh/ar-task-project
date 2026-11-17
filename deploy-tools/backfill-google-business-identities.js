// Dry run by default. --apply only adds canonical URLs and missing exclusion keys;
// it never changes task status, ownership, earnings, balances, or reviews.
const fs = require('node:fs');
const path = require('node:path');

async function main() {
  const backend = process.env.BACKEND_ROOT || '/opt/task-engine';
  const build = process.env.BACKEND_BUILD_DIR || path.join(backend, 'dist');
  require(path.join(backend, 'node_modules/dotenv')).config({ path: path.join(backend, '.env'), quiet: true });
  const mysql = require(path.join(backend, 'node_modules/mysql2/promise'));
  const { canonicalizeGoogleBusinessTarget, extractTaskIdentity } = require(path.join(build, 'shared/common/utils/task-identity.util'));
  const apply = process.argv.includes('--apply');
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST || 'localhost', user: process.env.DB_USERNAME || 'taskapp',
    password: process.env.DB_PASSWORD, database: process.env.DB_DATABASE || 'task_platform',
  });
  const query = async (sql, params) => (await connection.query(sql, params))[0];
  const parse = (value) => typeof value === 'string' ? JSON.parse(value) : value || {};
  const targetOf = (req) => req.originalTargetUrl || req.targetUrl || req.url || req.link || '';
  const backup = { apply, orders: [], tasks: [], ledgerCandidates: [], startedAt: new Date().toISOString() };
  const backupFile = process.env.IDENTITY_BACKUP_FILE;
  if (apply && !backupFile) throw new Error('IDENTITY_BACKUP_FILE is required with --apply');
  const saveBackup = () => {
    if (apply) fs.writeFileSync(backupFile, JSON.stringify(backup), { mode: 0o600 });
  };
  try {
    const orders = await query('SELECT id, task_type, service_code, requirements FROM orders');
    const allTasks = await query('SELECT id, order_id, task_type, requirements, metadata, assigned_to FROM tasks');
    const selected = orders.filter((order) => {
      const req = parse(order.requirements);
      const label = [order.task_type, order.service_code, req.platform, targetOf(req)].join(' ');
      return /business|gmb|gmap|maps|share\.google|g\.page/i.test(label);
    });
    const users = await query("SELECT u.id, u.email, w.id worker_id FROM users u LEFT JOIN workers w ON w.user_id=u.id WHERE u.role='WORKER'");
    const aliases = new Map();
    for (const user of users) {
      const ids = [...new Set([user.id, user.email, user.worker_id].filter(Boolean).map((id) => id.toLowerCase().trim()))];
      for (const id of ids) aliases.set(id, ids);
    }
    const resolved = new Map();
    const failures = [];
    for (const order of selected) {
      const records = [{ type: 'order', record: order }, ...allTasks.filter((task) => task.order_id === order.id).map((task) => ({ type: 'task', record: task }))];
      for (const { record } of records) {
        const req = parse(record.requirements);
        const raw = targetOf(req);
        if (resolved.has(raw)) continue;
        try {
          resolved.set(raw, await canonicalizeGoogleBusinessTarget({ ...req, targetUrl: raw }));
        } catch (error) {
          resolved.set(raw, null);
          failures.push({ orderId: order.id, url: raw, error: error.message });
        }
        console.log(JSON.stringify({ phase: 'link', resolved: Boolean(resolved.get(raw)), checked: resolved.size }));
      }
    }
    console.log(JSON.stringify({ phase: 'resolved', apply, orders: selected.length, uniqueLinks: resolved.size, unresolvedLinks: failures.length }));
    let ordersUpdated = 0, tasksUpdated = 0, ledgerAdded = 0;
    for (const order of selected) {
      if (apply) await connection.beginTransaction();
      try {
        const lockedOrders = await query('SELECT id, requirements FROM orders WHERE id=?' + (apply ? ' FOR UPDATE' : ''), [order.id]);
        if (!lockedOrders.length) { if (apply) await connection.commit(); continue; }
        const req = parse(lockedOrders[0].requirements);
        const canonical = resolved.get(targetOf(req));
        if (canonical) {
          backup.orders.push({ id: order.id, canonicalUrl: req.canonicalUrl, originalTargetUrl: req.originalTargetUrl });
          saveBackup();
          if (apply) await query(`UPDATE orders SET updated_at=updated_at, requirements=JSON_SET(COALESCE(requirements, JSON_OBJECT()),
            '$.canonicalUrl', ?, '$.originalTargetUrl', ?) WHERE id=?`, [canonical.canonicalUrl, canonical.originalTargetUrl, order.id]);
          ordersUpdated++;
        }
        const tasks = await query('SELECT id, requirements, metadata, assigned_to FROM tasks WHERE order_id=?' + (apply ? ' FOR UPDATE' : ''), [order.id]);
        if (!tasks.length) { if (apply) await connection.commit(); continue; }
        const taskIds = tasks.map((task) => task.id);
        const placeholders = taskIds.map(() => '?').join(',');
        const history = await query(`SELECT task_id, worker_id FROM task_assignments WHERE task_id IN (${placeholders})
          UNION ALL SELECT task_id, worker_id FROM task_submissions WHERE task_id IN (${placeholders})`, [...taskIds, ...taskIds]);
        const keys = new Map();
        for (const task of tasks) {
          const old = parse(task.requirements);
          const value = resolved.get(targetOf(old));
          if (!value) continue;
          const requirements = { ...old, canonicalUrl: value.canonicalUrl, originalTargetUrl: value.originalTargetUrl };
          backup.tasks.push({ id: task.id, canonicalUrl: old.canonicalUrl, originalTargetUrl: old.originalTargetUrl });
          saveBackup();
          if (apply) await query(`UPDATE tasks SET updated_at=updated_at, requirements=JSON_SET(COALESCE(requirements, JSON_OBJECT()),
            '$.canonicalUrl', ?, '$.originalTargetUrl', ?) WHERE id=?`, [value.canonicalUrl, value.originalTargetUrl, task.id]);
          tasksUpdated++;
          const identity = extractTaskIdentity({ requirements, metadata: parse(task.metadata) });
          const workers = [task.assigned_to, ...history.filter((row) => row.task_id === task.id).map((row) => row.worker_id)].filter(Boolean);
          for (const worker of workers) {
            const normalized = worker.toLowerCase().trim();
            for (const alias of aliases.get(normalized) || [normalized]) {
              for (const key of identity.entityKeys.filter((key) => key.length <= 191)) {
                keys.set(`${alias}\u0000${key}`, [alias, key, task.id]);
              }
            }
          }
        }
        const entries = [...keys.values()];
        for (let offset = 0; offset < entries.length; offset += 300) {
          const batch = entries.slice(offset, offset + 300);
          if (apply) {
            // Additive INSERT IGNORE preserves every existing historical key/task reference.
            const result = await query(`INSERT IGNORE INTO worker_completed_identities (worker_key,entity_key,task_id)
              VALUES ${batch.map(() => '(?,?,?)').join(',')}`, batch.flat());
            ledgerAdded += result.affectedRows;
          }
        }
        backup.ledgerCandidates.push({ orderId: order.id, candidateKeys: entries.length });
        saveBackup();
        if (apply) await connection.commit();
        console.log(JSON.stringify({ phase: 'order', orderId: order.id, candidateKeys: entries.length }));
      } catch (error) {
        if (apply) await connection.rollback();
        throw error;
      }
    }
    console.log(JSON.stringify({ phase: 'complete', apply, ordersUpdated, tasksUpdated, ledgerAdded, unresolved: failures }));
  } finally {
    await connection.end();
  }
}

main().catch((error) => { console.error(error.message); process.exitCode = 1; });
