const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

(async () => {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== SYSTEMCTL STATUS PM2-ROOT ===');
    console.log((await ssh.execCommand('systemctl status pm2-root --no-pager')).stdout);

    console.log('\n=== JOURNALCTL PM2-ROOT RECENT (last 30) ===');
    console.log((await ssh.execCommand('journalctl -u pm2-root -n 30 --no-pager')).stdout);

    console.log('\n=== CAT /etc/systemd/system/pm2-root.service ===');
    console.log((await ssh.execCommand('cat /etc/systemd/system/pm2-root.service')).stdout);

    console.log('\n=== TASK ENGINE API ERROR LOG (last 50 lines) ===');
    console.log((await ssh.execCommand('tail -n 50 /root/.pm2/logs/task-engine-api-error-2.log')).stdout);

    console.log('\n=== TASK ENGINE WORKER ERROR LOG (last 50 lines) ===');
    console.log((await ssh.execCommand('tail -n 50 /root/.pm2/logs/task-engine-worker-error-3.log 2>/dev/null || true')).stdout);

    console.log('\n=== NGINX ERROR LOG (last 30 lines) ===');
    console.log((await ssh.execCommand('tail -n 30 /var/log/nginx/error.log 2>/dev/null || true')).stdout);

    ssh.dispose();
  } catch (err) {
    console.error('SSH Error:', err.message);
    ssh.dispose();
  }
})();
