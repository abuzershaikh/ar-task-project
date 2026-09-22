const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

(async () => {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== END OF TASK-ENGINE-API OUT LOG FROM SEP 19 ===');
    console.log((await ssh.execCommand('tail -n 60 /root/.pm2/logs/task-engine-api-out-2__2026-09-19_22-21-32.log')).stdout);

    console.log('\n=== ANY ERRORS IN ERROR LOG ON SEP 19 ===');
    console.log((await ssh.execCommand('ls -laht /root/.pm2/logs/task-engine*error*')).stdout);
    console.log((await ssh.execCommand('tail -n 60 /root/.pm2/logs/task-engine-api-error-2__2026-09-19_22-21-32.log 2>/dev/null || tail -n 60 /root/.pm2/logs/task-engine-api-error-2.log')).stdout);

    console.log('\n=== CHECK WHAT WAS IN /root/.pm2/dump.pm2 ===');
    console.log((await ssh.execCommand('cat /root/.pm2/dump.pm2 | grep -o -E \'"name":"[^"]+"\' | head -n 10')).stdout);

    console.log('\n=== CHECK PM2 LOG FILE SYSTEMCTL / JOURNALCTL ===');
    console.log((await ssh.execCommand('journalctl -u pm2-root --lines 40 --no-pager 2>&1')).stdout);

    ssh.dispose();
  } catch (err) {
    console.error('SSH Error:', err.message);
    ssh.dispose();
  }
})();
