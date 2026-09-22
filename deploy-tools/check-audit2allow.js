const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

(async () => {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== CHECK AUDIT2ALLOW AVAILABILITY ===');
    console.log((await ssh.execCommand('which audit2allow 2>&1')).stdout);

    console.log('\n=== GENERATE AUDIT2ALLOW FOR SYSTEMD PM2 ===');
    const gen = await ssh.execCommand('grep "pm2.pid" /var/log/audit/audit.log | tail -n 20 | audit2allow -m pm2_systemd');
    console.log(gen.stdout || gen.stderr);

    ssh.dispose();
  } catch (err) {
    console.error('SSH Error:', err.message);
    ssh.dispose();
  }
})();
