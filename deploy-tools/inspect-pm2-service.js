const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

(async () => {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== CAT /etc/systemd/system/pm2-root.service ===');
    console.log((await ssh.execCommand('cat /etc/systemd/system/pm2-root.service 2>/dev/null || cat /usr/lib/systemd/system/pm2-root.service')).stdout);

    console.log('\n=== CHECK SELINUX STATUS ===');
    console.log((await ssh.execCommand('getenforce 2>&1')).stdout);

    console.log('\n=== CHECK PERMISSIONS ON /root/.pm2 ===');
    console.log((await ssh.execCommand('ls -ld /root /root/.pm2 /root/.pm2/pm2.pid')).stdout);

    ssh.dispose();
  } catch (err) {
    console.error('SSH Error:', err.message);
    ssh.dispose();
  }
})();
