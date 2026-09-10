const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 15000,
  });

  console.log('=== Grepping youtube-video-info in pm2 logs ===');
  const r1 = await ssh.execCommand('grep -rn "youtube-video-info" /root/.pm2/logs/');
  console.log(r1.stdout || '(no matches)');

  console.log('=== Grepping YouTubeMetadataService in pm2 logs ===');
  const r2 = await ssh.execCommand('grep -rn "YouTubeMetadataService" /root/.pm2/logs/');
  console.log(r2.stdout || '(no matches)');

  console.log('=== Checking recent order creation logs ===');
  const r3 = await ssh.execCommand('grep -rn "/api/v1/buyer/orders" /root/.pm2/logs/ | tail -n 20');
  console.log(r3.stdout || '(no matches)');

  ssh.dispose();
}

run();
