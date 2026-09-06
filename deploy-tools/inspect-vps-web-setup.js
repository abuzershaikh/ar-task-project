
const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();
async function inspect() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });
  console.log('Connected to VPS!');
  const commands = [
    'ls -la /var/www/buyer-web',
    'head -n 25 /var/www/buyer-web/index.html',
  ];
  for (const cmd of commands) {
    console.log('=== ' + cmd + ' ===');
    const res = await ssh.execCommand(cmd);
    console.log(res.stdout || res.stderr);
  }
  process.exit(0);
}
inspect().catch(e => { console.error(e); process.exit(1); });
