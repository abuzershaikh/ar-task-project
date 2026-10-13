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

  const [u] = await pool.query("SELECT id, email, full_name FROM users WHERE id = 'VKhB4NlZWmVVFy37RhS76rS1dnp2'");
  console.log('User VKhB4NlZWmVVFy37RhS76rS1dnp2:', u[0]);

  const [wList] = await pool.query('SELECT id, user_id, total_tasks_completed, total_earnings, last_active_at, created_at FROM workers WHERE user_id = ?', ['VKhB4NlZWmVVFy37RhS76rS1dnp2']);
  for (const w of wList) {
    const [tasks] = await pool.query('SELECT COUNT(*) as c FROM tasks WHERE worker_id = ?', [w.id]);
    const [subs] = await pool.query('SELECT COUNT(*) as c FROM task_submissions WHERE worker_id = ?', [w.id]);
    const [earnings] = await pool.query('SELECT COUNT(*) as c FROM earnings WHERE worker_id = ?', [w.id]);
    console.log('  worker id:', w.id, 'tasks_completed:', w.total_tasks_completed, 'tasks:', tasks[0].c, 'subs:', subs[0].c, 'earnings:', earnings[0].c, 'last_active:', w.last_active_at);
  }

  await pool.end();
}

run().then(() => process.exit(0)).catch(e => { console.error(e); process.exit(1); });
    `;

    await ssh.execCommand("cat << 'EOF' > /root/check_top_worker.js\n" + script + "\nEOF");
    const res = await ssh.execCommand('NODE_PATH=/opt/task-engine/node_modules node /root/check_top_worker.js');
    console.log(res.stdout);
    if (res.stderr) console.error(res.stderr);

    ssh.dispose();
  } catch (e) {
    console.error(e);
  }
})();
