const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 15000,
  });

  const sql1 = `mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, task_type, status, assigned_to FROM tasks WHERE requirements LIKE '%com.contactsaver.autocontactsaver%';"`;
  const res1 = await ssh.execCommand(sql1);
  console.log('Tasks with contactsaver:\n', res1.stdout);

  const sql2 = `mysql -u taskapp -ptaskapp_password task_platform -e "SELECT s.id, s.task_id, s.worker_id, s.status, t.order_id, t.requirements FROM submissions s JOIN tasks t ON s.task_id = t.id WHERE s.worker_id IN ('sufieditz@gmail.com', 'kQzd3bZD7pgA908xGE6NoGogetB3') ORDER BY s.created_at DESC LIMIT 10;"`;
  const res2 = await ssh.execCommand(sql2);
  console.log('Recent submissions by sufi:\n', res2.stdout);

  process.exit(0);
}

run().catch(console.error);
