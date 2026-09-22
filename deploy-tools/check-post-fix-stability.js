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

    console.log('\n=== PM2 STATUS & UPTIME ===');
    console.log((await ssh.execCommand('pm2 status')).stdout);

    console.log('\n=== DETAILED API STATUS ===');
    console.log((await ssh.execCommand('pm2 describe task-engine-api | grep -E "status|uptime|restarts"')).stdout);

    console.log('\n=== CURL HEALTH CHECK ===');
    console.log((await ssh.execCommand('curl -i -s http://127.0.0.1:3000/api/docs 2>&1 | head -n 15')).stdout);

    console.log('\n=== JOURNALCTL SINCE LAST RESTART ===');
    console.log((await ssh.execCommand('journalctl -u pm2-root -n 20 --no-pager')).stdout);

    ssh.dispose();
  } catch (err) {
    console.error('Error:', err.message);
    ssh.dispose();
  }
})();
