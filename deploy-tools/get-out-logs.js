const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function getOutLogs() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
    const res = await ssh.execCommand('tail -n 120 /root/.pm2/logs/task-engine-api-out-2.log');
    console.log(res.stdout);
  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

getOutLogs();
