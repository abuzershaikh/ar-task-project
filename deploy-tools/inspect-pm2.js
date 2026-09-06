const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function checkPm2() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== PM2 LOGS (Last 40 lines) ===');
    const logs = await ssh.execCommand('pm2 logs task-engine-api --lines 40 --nostream');
    console.log(logs.stdout || logs.stderr);
  } catch (e) {
    console.error(e.message);
  } finally {
    ssh.dispose();
    process.exit(0);
  }
}

checkPm2();
