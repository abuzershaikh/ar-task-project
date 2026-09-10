const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function debug() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });

const debugScript = `
async function run() {
  const mysql = require('/opt/task-engine/node_modules/mysql2/promise');
  const conn = await mysql.createConnection({
    host: '127.0.0.1',
    user: 'taskapp',
    password: 'taskapp_password',
    database: 'task_platform'
  });

  const workerId = 'MYDovhuR8zcbLlvazaAG8qdWLXr1';
  console.log('WorkerId input:', workerId);

  const [users] = await conn.query('SELECT * FROM users WHERE id = ? OR email = ?', [workerId, workerId]);
  console.log('User found:', users);

  const [workers] = await conn.query('SELECT * FROM workers WHERE user_id = ? OR id = ?', [workerId, workerId]);
  console.log('Worker profiles found:', workers);

  const [parts] = await conn.query('SELECT * FROM campaign_worker_participation WHERE worker_id = ?', [workerId]);
  console.log('Participations for worker_id=' + workerId + ':', parts);

  const [workerTasks] = await conn.query('SELECT id, status, campaign_id, order_id, assigned_to FROM tasks WHERE assigned_to = ?', [workerId]);
  console.log('Tasks assigned to worker_id=' + workerId + ':', workerTasks);

  const [availTasks] = await conn.query('SELECT id, status, campaign_id, order_id, assigned_to FROM tasks WHERE status IN ("active", "ACTIVE") AND (assigned_to IS NULL OR assigned_to = "")');
  console.log('Available tasks total count:', availTasks.length);
  for (const t of availTasks) {
    console.log('Avail task:', t.id, 'status:', t.status, 'campaignId:', t.campaign_id, 'orderId:', t.order_id);
  }

  await conn.end();
}

run().catch(console.error);
`;

    await ssh.execCommand(`cat << 'EOF' > /tmp/debug-query.js\n${debugScript}\nEOF`);
    const res = await ssh.execCommand('node /tmp/debug-query.js');
    console.log(res.stdout);
    if (res.stderr) console.log('STDERR:\n', res.stderr);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

debug();
