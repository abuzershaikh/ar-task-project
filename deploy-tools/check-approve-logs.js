const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function checkApproveLogs() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });

    console.log('=== PM2 Logs (Last 100 lines) ===');
    const logsRes = await ssh.execCommand('pm2 logs task-engine-api --lines 100 --nostream');
    console.log(logsRes.stdout);
    if (logsRes.stderr) console.log('STDERR:\n', logsRes.stderr);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

checkApproveLogs();
