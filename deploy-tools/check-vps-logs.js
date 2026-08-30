const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function checkLogs() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });

    console.log('=== PM2 Logs (Last 100 lines) ===');
    const logsRes = await ssh.execCommand('pm2 logs task-engine-api --lines 100 --nostream');
    console.log(logsRes.stdout);
    if (logsRes.stderr) console.log('STDERR:\n', logsRes.stderr);

    console.log('\n=== Check /opt/task-engine/uploads folder ===');
    const uploadsRes = await ssh.execCommand('ls -la /opt/task-engine/uploads');
    console.log(uploadsRes.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

checkLogs();
