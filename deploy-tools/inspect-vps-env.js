const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });
  const res = await ssh.execCommand('cat /opt/task-engine/.env');
  console.log('--- /opt/task-engine/.env ---');
  res.stdout.split('\n').forEach(line => {
    if (line.match(/CORS|ORIGIN|DOMAIN|URL|FRONTEND|HOST|APP/i)) {
      console.log(line);
    }
  });

  const pm2Res = await ssh.execCommand('pm2 list');
  console.log('\n--- PM2 processes ---');
  console.log(pm2Res.stdout);

  ssh.dispose();
}
run().catch(console.error);
