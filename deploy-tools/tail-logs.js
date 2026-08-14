const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function tailLogs() {
  await ssh.connect({
    host: '95.179.178.6',
    username: 'root',
    password: 'i_G72#y}(6gACDDU'
  });
  
  console.log('=== REAL TIME PM2 LOGS ===');
  const res = await ssh.execCommand('pm2 logs task-engine --lines 30 --nostream');
  console.log(res.stdout || res.stderr);

  ssh.dispose();
}
tailLogs();
