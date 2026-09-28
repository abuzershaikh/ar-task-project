const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  const orderId = '732cbd88-15bb-4233-bf46-4a32ebc9df0e';

  console.log('=== FULL METADATA OF THE 5 SUBMITTED TASKS ===');
  const subs = await ssh.execCommand(`mysql -u taskapp -p'taskapp_password' task_platform -e "SELECT id, status, assigned_to, started_at, submitted_at, metadata FROM tasks WHERE order_id='${orderId}' AND status='under_review'\\G"`);
  console.log(subs.stdout);

  ssh.dispose();
}

run();
