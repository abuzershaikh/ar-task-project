const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

(async () => {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    const script = `
const mysql = require('mysql2/promise');

async function run() {
  const pool = await mysql.createPool({
    host: 'localhost',
    user: 'taskapp',
    password: 'taskapp_password',
    database: 'task_platform',
  });

  const [dupUsers] = await pool.query(\`
    SELECT user_id, COUNT(*) as cnt 
    FROM workers 
    WHERE user_id IS NOT NULL AND user_id != ''
    GROUP BY user_id 
    HAVING cnt > 1 
    ORDER BY cnt DESC
  \`);

  console.log('Duplicate users count:', dupUsers.length);
  for (const { user_id, cnt } of dupUsers) {
    const [wList] = await pool.query('SELECT id, user_id, total_tasks_completed, total_earnings, last_active_at, created_at FROM workers WHERE user_id = ?', [user_id]);
    console.log('User:', user_id, 'Count:', cnt);
    for (const w of wList) {
      const [tasks] = await pool.query('SELECT COUNT(*) as c FROM tasks WHERE worker_id = ?', [w.id]);
      const [subs] = await pool.query('SELECT COUNT(*) as c FROM task_submissions WHERE worker_id = ?', [w.id]);
      const [earnings] = await pool.query('SELECT COUNT(*) as c FROM earnings WHERE worker_id = ?', [w.id]);
      console.log('  worker id:', w.id, 'tasks_completed:', w.total_tasks_completed, 'tasks:', tasks[0].c, 'subs:', subs[0].c, 'earnings:', earnings[0].c, 'last_active:', w.last_active_at);
    }
  }

  await pool.end();
}

run().then(() => process.exit(0)).catch(e => { console.error(e); process.exit(1); });
    `;

    await ssh.execCommand("cat << 'EOF' > /root/check_worker_refs.js\n" + script + "\nEOF");
    const res = await ssh.execCommand('NODE_PATH=/opt/task-engine/node_modules node /root/check_worker_refs.js');
    console.log(res.stdout);
    if (res.stderr) console.error(res.stderr);

    ssh.dispose();
  } catch (e) {
    console.error(e);
  }
})();
