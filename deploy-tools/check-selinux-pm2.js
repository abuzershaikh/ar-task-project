const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

(async () => {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== AUDIT LOGS FOR PM2 / SELINUX ===');
    console.log((await ssh.execCommand('grep -i "pm2" /var/log/audit/audit.log 2>/dev/null | tail -n 15')).stdout);

    console.log('\n=== CURRENT SYSTEMCTL STATUS PM2-ROOT ===');
    console.log((await ssh.execCommand('systemctl status pm2-root --no-pager')).stdout);

    ssh.dispose();
  } catch (err) {
    console.error('SSH Error:', err.message);
    ssh.dispose();
  }
})();
