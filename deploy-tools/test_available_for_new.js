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

    console.log('--- TEST: HOW MANY TASKS CAN ajaykumardhiman731 SEE RIGHT NOW? ---');
    console.log(await runSql(`
      SELECT COUNT(*) as available_for_new_user
      FROM tasks t
      LEFT JOIN orders o ON o.id = t.order_id
      WHERE t.status = 'active'
        AND (t.assigned_to IS NULL OR t.assigned_to = '')
        AND (o.id IS NULL OR o.status IN ('ACTIVE', 'IN_PROGRESS'));
    `));

    console.log('--- CHECK RECENT ORDER CREATED TODAY (OCT 4) ---');
    console.log(await runSql(`
      SELECT o.id, o.title, o.status, o.total_tasks_required, o.tasks_completed, o.created_at
      FROM orders o
      WHERE o.created_at >= '2026-10-04 00:00:00'
      ORDER BY o.created_at DESC;
    `));

    console.log('--- TASKS FROM TODAY ORDER (OCT 4): WHO GOT THEM? ---');
    console.log(await runSql(`
      SELECT t.id, t.order_id, t.status, ta.worker_id, u.full_name, u.email, ta.status as assignment_status, ta.created_at as assigned_at
      FROM tasks t
      JOIN task_assignments ta ON ta.task_id = t.id
      JOIN users u ON (u.id = ta.worker_id OR u.email = ta.worker_id)
      WHERE t.order_id = '81b81a72-a672-42ed-a4b5-799bae3680ca'
      ORDER BY ta.created_at ASC;
    `));

    ssh.dispose();
  } catch (err) {
    console.error('Error:', err);
    ssh.dispose();
  }
})();
