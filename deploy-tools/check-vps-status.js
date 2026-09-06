const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function check() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });
    const pm2 = await ssh.execCommand('pm2 status');
    console.log('PM2 Status:\n', pm2.stdout);
    const fw = await ssh.execCommand('firewall-cmd --list-all');
    console.log('Firewall:\n', fw.stdout);
    const ports = await ssh.execCommand('ss -tulpn');
    console.log('Listening ports:\n', ports.stdout);
  } catch (e) {
    console.error('Error:', e.message);
  } finally {
    process.exit(0);
  }
}

check();
