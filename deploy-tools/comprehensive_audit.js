const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

(async () => {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== Connected to VPS for Audit ===\n');

    const runSql = async (sql) => {
      const escaped = sql.replace(/"/g, '\\"');
      const res = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "${escaped}"`);
      return res.stdout;
    };

    console.log('1. --- RECENT WORKERS REGISTERED (LAST 5 DAYS: OCT 1 - OCT 4) ---');
    console.log(await runSql(`
      SELECT u.id, u.name, u.email, u.created_at, w.status as worker_status, w.kyc_status,
             (SELECT COUNT(*) FROM task_assignments ta WHERE ta.worker_id = u.id OR ta.worker_id = u.email) as total_assignments,
             (SELECT COUNT(*) FROM task_submissions ts WHERE ts.worker_id = u.id OR ts.worker_id = u.email) as total_submissions
      FROM users u
      LEFT JOIN workers w ON (w.user_id = u.id OR w.id = u.id)
      WHERE u.role = 'WORKER' AND u.created_at >= '2026-10-01 00:00:00'
      ORDER BY u.created_at DESC;
    `));

    console.log('\n2. --- SUMMARY OF NEW WORKERS (OCT 1 - OCT 4) VS TASKS RECEIVED ---');
    console.log(await runSql(`
      SELECT 
        DATE(u.created_at) as reg_date,
        COUNT(u.id) as new_users_count,
        SUM(CASE WHEN EXISTS (
          SELECT 1 FROM task_assignments ta WHERE ta.worker_id = u.id OR ta.worker_id = u.email
        ) THEN 1 ELSE 0 END) as users_with_assignments,
        SUM(CASE WHEN EXISTS (
          SELECT 1 FROM task_submissions ts WHERE ts.worker_id = u.id OR ts.worker_id = u.email
        ) THEN 1 ELSE 0 END) as users_with_submissions
      FROM users u
      WHERE u.role = 'WORKER' AND u.created_at >= '2026-09-25 00:00:00'
      GROUP BY DATE(u.created_at)
      ORDER BY reg_date DESC;
    `));

    console.log('\n3. --- ALL TIME WORKERS: HOW MANY USERS NEVER GOT A TASK? ---');
    console.log(await runSql(`
      SELECT 
        COUNT(*) as total_workers,
        SUM(CASE WHEN (
          (SELECT COUNT(*) FROM task_assignments ta WHERE ta.worker_id = u.id OR ta.worker_id = u.email) > 0 OR
          (SELECT COUNT(*) FROM task_submissions ts WHERE ts.worker_id = u.id OR ts.worker_id = u.email) > 0
        ) THEN 1 ELSE 0 END) as workers_got_tasks,
        SUM(CASE WHEN (
          (SELECT COUNT(*) FROM task_assignments ta WHERE ta.worker_id = u.id OR ta.worker_id = u.email) = 0 AND
          (SELECT COUNT(*) FROM task_submissions ts WHERE ts.worker_id = u.id OR ts.worker_id = u.email) = 0
        ) THEN 1 ELSE 0 END) as workers_never_got_task
      FROM users u
      WHERE u.role = 'WORKER';
    `));

    console.log('\n4. --- ACTIVE ORDERS WITH PENDING UNITS ---');
    console.log(await runSql(`
      SELECT o.id, o.title, o.status, o.total_tasks_required, o.tasks_completed,
             COUNT(ou.id) as total_units_in_db,
             SUM(CASE WHEN ou.status = 'PENDING' THEN 1 ELSE 0 END) as pending_units,
             SUM(CASE WHEN ou.status = 'ASSIGNED' THEN 1 ELSE 0 END) as assigned_units,
             SUM(CASE WHEN ou.status = 'COMPLETED' THEN 1 ELSE 0 END) as completed_units,
             (SELECT COUNT(*) FROM tasks t WHERE t.order_id = o.id AND (t.assigned_to IS NULL OR t.assigned_to = '') AND t.status = 'active') as unassigned_active_tasks
      FROM orders o
      LEFT JOIN order_units ou ON ou.order_id = o.id
      WHERE o.status = 'ACTIVE'
      GROUP BY o.id, o.title, o.status, o.total_tasks_required, o.tasks_completed
      ORDER BY o.created_at DESC;
    `));

    console.log('\n5. --- HOW ARE AVAILABLE TASKS COMPUTED FOR A BRAND NEW WORKER? ---');
    console.log(await runSql(`
      SELECT t.id, t.order_id, t.title, t.status, t.assigned_to, o.title as order_title, o.status as order_status
      FROM tasks t
      LEFT JOIN orders o ON o.id = t.order_id
      WHERE t.status = 'active'
        AND (t.assigned_to IS NULL OR t.assigned_to = '')
        AND (o.id IS NULL OR o.status IN ('ACTIVE', 'IN_PROGRESS'))
      LIMIT 10;
    `));

    console.log('\n6. --- TOTAL UNASSIGNED ACTIVE TASKS READY IN DB ---');
    console.log(await runSql(`
      SELECT COUNT(*) as total_ready_available_tasks
      FROM tasks t
      LEFT JOIN orders o ON o.id = t.order_id
      WHERE t.status = 'active'
        AND (t.assigned_to IS NULL OR t.assigned_to = '')
        AND (o.id IS NULL OR o.status IN ('ACTIVE', 'IN_PROGRESS'));
    `));

    ssh.dispose();
  } catch (err) {
    console.error('Error:', err);
    ssh.dispose();
  }
})();
