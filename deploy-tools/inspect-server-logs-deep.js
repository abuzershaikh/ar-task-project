const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

(async () => {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== LIST ALL PM2 LOG FILES ===');
    console.log((await ssh.execCommand('ls -laht /root/.pm2/logs/')).stdout);

    console.log('\n=== RECENT CRASH / ERROR LOGS IN ALL PM2 ERROR FILES ===');
    console.log((await ssh.execCommand('for f in /root/.pm2/logs/*error*.log; do echo "--- $f ---"; tail -n 25 "$f"; done')).stdout);

    console.log('\n=== CHECK DMESG OOM KILLER (OUT OF MEMORY) ===');
    console.log((await ssh.execCommand('dmesg -T | grep -i -E "oom|killed process|out of memory" | tail -n 20')).stdout);

    console.log('\n=== CHECK SYSTEM REBOOT HISTORY ===');
    console.log((await ssh.execCommand('last reboot | head -n 10')).stdout);

    console.log('\n=== CHECK SYSTEM CRON OR SCHEDULED REBOOTS ===');
    console.log((await ssh.execCommand('crontab -l')).stdout);

    ssh.dispose();
  } catch (err) {
    console.error('SSH Error:', err.message);
    ssh.dispose();
  }
})();
