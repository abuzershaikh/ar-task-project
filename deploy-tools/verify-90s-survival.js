const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

(async () => {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('Sleeping 85 seconds to cross the 90s boundary...');
    await new Promise(r => setTimeout(r, 85000));

    console.log('=== SYSTEMCTL STATUS PM2-ROOT ===');
    console.log((await ssh.execCommand('systemctl status pm2-root --no-pager')).stdout);

    console.log('\n=== PM2 STATUS & UPTIME ===');
    console.log((await ssh.execCommand('pm2 status')).stdout);

    console.log('\n=== DETAILED API STATUS ===');
    console.log((await ssh.execCommand('pm2 describe task-engine-api | grep -E "status|uptime|restarts"')).stdout);

    console.log('\n=== CURL API ENDPOINTS ===');
    console.log((await ssh.execCommand('curl -i -s http://127.0.0.1:3000/api/v1/auth/health 2>&1 || curl -i -s http://127.0.0.1:3000/api/docs | head -n 10')).stdout);

    ssh.dispose();
  } catch (err) {
    console.error('Error:', err.message);
    ssh.dispose();
  }
})();
