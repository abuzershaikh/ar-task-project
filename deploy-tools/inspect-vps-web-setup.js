
const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();
async function inspect() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u{5m46buXgw',
  });
  console.log('Connected to VPS!');
  const commands = [
    'nginx -t || true',
    'ls -la /var/www/',
    'ls -la /etc/nginx/conf.d/ || true',
    'cat /etc/nginx/conf.d/*.conf || true',
    'cat /etc/nginx/nginx.conf || true',
  ];
  for (const cmd of commands) {
    console.log('=== ' + cmd + ' ===');
    const res = await ssh.execCommand(cmd);
    console.log(res.stdout || res.stderr);
  }
  process.exit(0);
}
inspect().catch(e => { console.error(e); process.exit(1); });
