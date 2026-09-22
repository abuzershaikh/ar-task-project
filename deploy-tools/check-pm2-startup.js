const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

(async () => {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== SYSTEMCTL PM2 STATUS ===');
    console.log((await ssh.execCommand('systemctl list-unit-files | grep -i pm2')).stdout);
    console.log((await ssh.execCommand('systemctl status pm2-root --no-pager 2>&1')).stdout);

    console.log('\n=== PM2 DUMP FILE (/root/.pm2/dump.pm2) ===');
    console.log((await ssh.execCommand('ls -la /root/.pm2/dump.pm2')).stdout);

    console.log('\n=== TASK-ENGINE-API LOGS AROUND SEP 19 - SEP 22 ===');
    console.log((await ssh.execCommand('ls -laht /root/.pm2/logs/task-engine*')).stdout);

    console.log('\n=== NGINX ACCESS LOGS RECENT (to see incoming app requests) ===');
    console.log((await ssh.execCommand('tail -n 20 /var/log/nginx/access.log')).stdout);

    ssh.dispose();
  } catch (err) {
    console.error('SSH Error:', err.message);
    ssh.dispose();
  }
})();
