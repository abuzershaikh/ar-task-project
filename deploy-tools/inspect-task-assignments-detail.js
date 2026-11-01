const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  
  const sql = `SELECT * FROM task_assignments WHERE task_id IN ('011aa091-6888-4f86-b054-1d0a316eb1b1', '88e421cc-c37e-4919-a1b5-f8253e06ebc6');`;
  const res = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "${sql}"`);
  console.log('ASSIGNMENTS:\n', res.stdout);

  const logs = await ssh.execCommand(`grep -E "011aa091|88e421cc" /root/.pm2/logs/task-engine-api-out.log | tail -n 20`);
  console.log('PM2 OUT LOGS:\n', logs.stdout);

  const errLogs = await ssh.execCommand(`grep -E "011aa091|88e421cc" /root/.pm2/logs/task-engine-api-error.log | tail -n 20`);
  console.log('PM2 ERR LOGS:\n', errLogs.stdout);

  ssh.dispose();
}

run().catch(console.error);
