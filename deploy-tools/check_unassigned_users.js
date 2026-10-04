const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

(async () => {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== Checking Users without Tasks ===\n');

    const runSql = async (sql) => {
      const escaped = sql.replace(/"/g, '\\"');
      const res = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "${escaped}"`);
      return res.stdout;
    };

    console.log('--- RECENT WORKERS WHO HAVE 0 ASSIGNMENTS (OCT 1 - OCT 4) ---');
    console.log(await runSql(`
      SELECT u.id, u.name, u.email, u.created_at, w.last_active_at, w.status as worker_status, w.kyc_status
      FROM users u
      LEFT JOIN workers w ON (w.user_id = u.id OR w.id = u.id)
      WHERE u.role = 'WORKER' 
        AND u.created_at >= '2026-10-01 00:00:00'
        AND NOT EXISTS (
          SELECT 1 FROM task_assignments ta WHERE ta.worker_id = u.id OR ta.worker_id = u.email
        )
      ORDER BY u.created_at DESC;
    `));

    console.log('\n--- CHECK AVAILABLE TASKS FOR ONE OF THESE USERS VIA API ---');
    // Let's test calling the internal API /api/v1/worker/tasks/available or check token
    const sampleUser = await runSql(`
      SELECT u.id, u.email FROM users u 
      WHERE u.role = 'WORKER' AND u.created_at >= '2026-10-01 00:00:00'
        AND NOT EXISTS (SELECT 1 FROM task_assignments ta WHERE ta.worker_id = u.id OR ta.worker_id = u.email)
      LIMIT 1;
    `);
    console.log('Sample user:', sampleUser);

    console.log('\n--- ACTIVE TASKS THAT ANY NEW USER CAN CURRENTLY SEE ---');
    console.log(await runSql(`
      SELECT t.id, t.order_id, t.title, t.status, o.title as order_title
      FROM tasks t
      JOIN orders o ON o.id = t.order_id
      WHERE t.status = 'active'
        AND (t.assigned_to IS NULL OR t.assigned_to = '')
        AND o.status = 'ACTIVE'
      LIMIT 15;
    `));

    console.log('\n--- BREAKDOWN OF AVAILABLE TASKS BY ORDER ---');
    console.log(await runSql(`
      SELECT o.id as order_id, o.title, COUNT(t.id) as available_tasks_count
      FROM tasks t
      JOIN orders o ON o.id = t.order_id
      WHERE t.status = 'active'
        AND (t.assigned_to IS NULL OR t.assigned_to = '')
        AND o.status = 'ACTIVE'
      GROUP BY o.id, o.title;
    `));

    ssh.dispose();
  } catch (err) {
    console.error('Error:', err);
    ssh.dispose();
  }
})();
