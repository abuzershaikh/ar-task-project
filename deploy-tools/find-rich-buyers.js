const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 15000,
  });

  const res = await ssh.execCommand(
    "mysql task_platform -e 'SELECT u.id, u.email, u.role, w.available_balance FROM users u JOIN wallets w ON w.user_id = u.id WHERE u.role=\"BUYER\" ORDER BY w.available_balance DESC LIMIT 5;'"
  );
  console.log('=== BUYERS WITH BALANCE ===\n', res.stdout);

  ssh.dispose();
}

run().catch(console.error);
