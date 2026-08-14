const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function pushFromVPS() {
  await ssh.connect({
    host: '95.179.178.6',
    username: 'root',
    password: 'i_G72#y}(6gACDDU'
  });

  console.log('--- 1. Pushing with SSH Key from VPS server ---');
  const res = await ssh.execCommand('cd /var/www/task-engine && git push origin live-server --force');
  console.log('VPS PUSH OUTPUT:\n', res.stdout);
  console.log('VPS PUSH ERRORS/INFO:\n', res.stderr);

  ssh.dispose();
}

pushFromVPS();
