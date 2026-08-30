const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function checkEnv() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
    const res = await ssh.execCommand('grep -i "db_" /opt/task-engine/.env');
    console.log(res.stdout);
  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

checkEnv();
