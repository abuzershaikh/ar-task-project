const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });

  console.log('=== 1. Grep 401 in /var/log/nginx/access.log ===');
  const res1 = await ssh.execCommand('grep " 401 " /var/log/nginx/access.log | tail -n 25');
  console.log(res1.stdout || 'None in access.log');

  console.log('\n=== 2. Grep 403 in /var/log/nginx/access.log ===');
  const res2 = await ssh.execCommand('grep " 403 " /var/log/nginx/access.log | tail -n 25');
  console.log(res2.stdout || 'None in access.log');

  console.log('\n=== 3. Grep 401 in PM2 api logs ===');
  const res3 = await ssh.execCommand('grep -i " 401 " /root/.pm2/logs/task-engine-api-out.log | tail -n 25');
  console.log(res3.stdout || 'None in out.log');

  console.log('\n=== 4. Grep Unauthorized in PM2 api logs ===');
  const res4 = await ssh.execCommand('grep -i "Unauthorized" /root/.pm2/logs/task-engine-api-out.log /root/.pm2/logs/task-engine-api-error.log | tail -n 25');
  console.log(res4.stdout || 'None');

  console.log('\n=== 5. Grep Forbidden in PM2 api logs ===');
  const res5 = await ssh.execCommand('grep -i "Forbidden" /root/.pm2/logs/task-engine-api-out.log /root/.pm2/logs/task-engine-api-error.log | tail -n 25');
  console.log(res5.stdout || 'None');

  ssh.dispose();
}

run().catch(err => {
  console.error(err);
  ssh.dispose();
});
