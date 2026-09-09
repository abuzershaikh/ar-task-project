const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function checkTaskEngine() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
    console.log('--- CHECK /opt/task-engine ---');
    const ls = await ssh.execCommand('ls -la /opt/task-engine');
    console.log(ls.stdout);
  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

checkTaskEngine();
