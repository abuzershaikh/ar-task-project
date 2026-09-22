const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

(async () => {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== CREATING & INSTALLING SELINUX POLICY FOR PM2 SYSTEMD ===');
    const cmd1 = `ausearch -c 'systemd' --raw | grep -i "pm2.pid" | audit2allow -M pm2_systemd && semodule -i pm2_systemd.pp`;
    const res1 = await ssh.execCommand(cmd1);
    console.log('Output:', res1.stdout || res1.stderr || 'Success');

    console.log('\n=== CHECK SEMODULE LIST ===');
    console.log((await ssh.execCommand('semodule -l | grep pm2')).stdout);

    console.log('\n=== RESTART PM2-ROOT SERVICE ===');
    console.log((await ssh.execCommand('systemctl restart pm2-root')).stdout);

    console.log('\n=== SYSTEMCTL STATUS PM2-ROOT ===');
    console.log((await ssh.execCommand('systemctl status pm2-root --no-pager')).stdout);

    ssh.dispose();
  } catch (err) {
    console.error('SSH Error:', err.message);
    ssh.dispose();
  }
})();
