const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function inspect() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('--- PM2 STATUS ---');
    const pm2 = await ssh.execCommand('pm2 status');
    console.log(pm2.stdout);

    console.log('--- PM2 LOGS (support-chat-engine) ---');
    const logs = await ssh.execCommand('pm2 logs support-chat-engine --lines 30 --nostream');
    console.log(logs.stdout);
    if (logs.stderr) console.error('STDERR:', logs.stderr);

    console.log('--- NGINX reviewsgateway.conf ---');
    const nginxConf = await ssh.execCommand('head -n 40 /etc/nginx/conf.d/reviewsgateway.conf');
    console.log(nginxConf.stdout);

    ssh.dispose();
  } catch (err) {
    console.error(err);
    ssh.dispose();
  }
}

inspect();
