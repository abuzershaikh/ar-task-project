const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });
  console.log('Connected to VPS.');

  const res1 = await ssh.execCommand(
    "mysql -u taskapp -ptaskapp_password task_platform -e \"SELECT id, task_id, worker_id, attempt_number, status, created_at FROM task_assignments WHERE task_id = '78c1717a-dacd-4e86-b4d8-49974b37807d' ORDER BY attempt_number ASC;\""
  );
  console.log('--- task_assignments ---');
  console.log(res1.stdout || res1.stderr);

  const res2 = await ssh.execCommand(
    "mysql -u taskapp -ptaskapp_password task_platform -e \"SELECT id, status, assigned_to, attempt_count, created_at FROM tasks WHERE id = '78c1717a-dacd-4e86-b4d8-49974b37807d';\""
  );
  console.log('--- tasks ---');
  console.log(res2.stdout || res2.stderr);

  const res3 = await ssh.execCommand(
    "mysql -u taskapp -ptaskapp_password task_platform -e \"SELECT COUNT(*), MAX(attempt_number) FROM task_assignments WHERE task_id = '78c1717a-dacd-4e86-b4d8-49974b37807d';\""
  );
  console.log('--- count and max attempt ---');
  console.log(res3.stdout || res3.stderr);



  ssh.dispose();
}
run();
