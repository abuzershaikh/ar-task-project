const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  
  console.log('=== 1. Nginx recent 401 / 403 access log entries ===');
  const nginx401 = await ssh.execCommand('grep -E " (401|403) " /var/log/nginx/access.log | tail -n 40');
  console.log(nginx401.stdout || '(None found in /var/log/nginx/access.log)');

  console.log('\n=== 2. Nginx recent 20 requests ===');
  const nginxRecent = await ssh.execCommand('tail -n 25 /var/log/nginx/access.log');
  console.log(nginxRecent.stdout);

  console.log('\n=== 3. task-engine-api logs for Unauthorized or 401 ===');
  const apiLogs = await ssh.execCommand('pm2 logs task-engine-api --lines 120 --nostream');
  console.log(apiLogs.stdout);
  if (apiLogs.stderr) console.log('STDERR:\n', apiLogs.stderr);

  console.log('\n=== 4. Check active PM2 list ===');
  const pm2List = await ssh.execCommand('pm2 list');
  console.log(pm2List.stdout);

  ssh.dispose();
  process.exit(0);
}

run().catch(err => {
  console.error(err);
  ssh.dispose();
  process.exit(1);
});
