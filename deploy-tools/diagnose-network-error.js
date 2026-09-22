const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

(async () => {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== SYSTEM UPTIME ===');
    console.log((await ssh.execCommand('uptime')).stdout);

    console.log('\n=== LAST REBOOT ===');
    console.log((await ssh.execCommand('last reboot | head -n 5')).stdout);

    console.log('\n=== PM2 STATUS ===');
    console.log((await ssh.execCommand('pm2 status')).stdout);

    console.log('\n=== LOCAL CURL TEST TO API (port 3000) ===');
    console.log((await ssh.execCommand('curl -i http://127.0.0.1:3000/api/v1/health 2>&1')).stdout);

    console.log('\n=== PUBLIC CURL TEST VIA NGINX (http://localhost/api/v1/health) ===');
    console.log((await ssh.execCommand('curl -i http://127.0.0.1/api/v1/health 2>&1')).stdout);

    console.log('\n=== NGINX CONFIGS ===');
    console.log((await ssh.execCommand('cat /etc/nginx/conf.d/*.conf 2>/dev/null')).stdout);
    console.log((await ssh.execCommand('cat /etc/nginx/nginx.conf 2>/dev/null | grep -E "include|server" -A 10')).stdout);

    console.log('\n=== TEST ACTUAL APP ENDPOINTS (auth/login, tasks/available) ===');
    console.log((await ssh.execCommand('curl -i -X POST http://127.0.0.1:3000/api/v1/auth/login -H "Content-Type: application/json" -d "{}" 2>&1')).stdout);
    console.log((await ssh.execCommand('curl -i http://127.0.0.1:3000/api/v1/buyer/services 2>&1')).stdout);

    ssh.dispose();
  } catch (err) {
    console.error('SSH Error:', err.message);
    ssh.dispose();
  }
})();
