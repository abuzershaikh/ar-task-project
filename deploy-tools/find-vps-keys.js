const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw'
  });
  console.log('Searching for any API keys on VPS...');
  const res = await ssh.execCommand('grep -rn "sk-" /var/www /root /opt 2>/dev/null | head -n 30');
  console.log('KEYS FOUND:\n', res.stdout || 'NONE');
}

run().catch(console.error);
