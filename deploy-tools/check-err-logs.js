const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function tailLogs() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });
  
  console.log('=== REAL TIME PM2 LOGS ===');
  const res = await ssh.execCommand('tail -n 100 /root/.pm2/logs/task-engine-api-error-2.log');
  console.log(res.stdout || res.stderr);

  ssh.dispose();
}
tailLogs();
