const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function checkEnvAndLogs() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });

    console.log('=== PM2 logs list ===');
    const pm2Desc = await ssh.execCommand('pm2 describe task-engine-api');
    console.log(pm2Desc.stdout);

    console.log('=== Error logs from PM2 ===');
    const logsRes = await ssh.execCommand('tail -n 100 /root/.pm2/logs/*');
    console.log(logsRes.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

checkEnvAndLogs();
