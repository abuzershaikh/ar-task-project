const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

(async () => {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== PM2 STARTUP OUTPUT ===');
    console.log((await ssh.execCommand('pm2 startup systemd')).stdout);

    console.log('\n=== CHECK PM2 VERSION ===');
    console.log((await ssh.execCommand('pm2 -v')).stdout);

    console.log('\n=== CURRENT PROCESS LIST ===');
    console.log((await ssh.execCommand('pm2 status')).stdout);

    ssh.dispose();
  } catch (err) {
    console.error('SSH Error:', err.message);
    ssh.dispose();
  }
})();
