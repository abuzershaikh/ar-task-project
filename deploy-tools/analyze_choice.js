const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

(async () => {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    const runSql = async (sql) => {
      await ssh.execCommand(`cat << 'EOF' > /tmp/query.sql\n${sql}\nEOF`);
      const res = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform < /tmp/query.sql');
      return res.stdout || res.stderr;
    };

    console.log('--- WHAT ORDERS/TASKS DID ALL 16 NEW WORKERS OF TODAY (OCT 4) DO? ---');
    console.log(await runSql(`
      SELECT u.full_name, u.email, u.created_at,
             COUNT(ta.id) as total_tasks_taken,
             GROUP_CONCAT(DISTINCT SUBSTRING(ta.campaign_id, 1, 8)) as campaign_prefixes_taken
      FROM users u
      LEFT JOIN task_assignments ta ON (ta.worker_id = u.id OR ta.worker_id = u.email)
      WHERE u.role = 'WORKER' AND DATE(u.created_at) = '2026-10-04'
      GROUP BY u.id, u.full_name, u.email, u.created_at
      ORDER BY total_tasks_taken DESC;
    `));

    console.log('\n--- DID #732cbd88 APPEAR IN AVAILABLE TASKS FOR NEW WORKERS? ---');
    console.log(await runSql(`
      SELECT t.id, t.order_id, t.status, t.assigned_to, o.title
      FROM tasks t
      JOIN orders o ON o.id = t.order_id
      WHERE t.order_id LIKE '732cbd88%'
        AND t.status = 'active'
        AND (t.assigned_to IS NULL OR t.assigned_to = '')
      LIMIT 5;
    `));

    console.log('\n--- HOW MANY TOTAL ACTIVE CAMPAIGNS WERE COMPETING FOR WORKERS TODAY? ---');
    console.log(await runSql(`
      SELECT o.id, o.title, COUNT(t.id) as unassigned_tasks,
             (SELECT COUNT(*) FROM task_assignments ta WHERE (ta.order_id = o.id OR ta.campaign_id = o.id) AND DATE(ta.created_at) = '2026-10-04') as assignments_today
      FROM orders o
      JOIN tasks t ON t.order_id = o.id
      WHERE o.status = 'ACTIVE' AND t.status = 'active' AND (t.assigned_to IS NULL OR t.assigned_to = '')
      GROUP BY o.id, o.title
      ORDER BY assignments_today DESC;
    `));

    ssh.dispose();
  } catch (err) {
    console.error('Error:', err);
    ssh.dispose();
  }
})();
