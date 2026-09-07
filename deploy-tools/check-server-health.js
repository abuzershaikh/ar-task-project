const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

(async () => {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== PM2 STATUS ===');
    const s = await ssh.execCommand('pm2 status');
    console.log(s.stdout);

    console.log('\n=== ERROR LOGS (last 30 lines) ===');
    const e = await ssh.execCommand('pm2 logs task-engine-api --err --lines 30 --nostream');
    console.log(e.stdout || e.stderr);

    console.log('\n=== OUT LOGS (last 20 lines) ===');
    const o = await ssh.execCommand('pm2 logs task-engine-api --out --lines 20 --nostream');
    console.log(o.stdout || o.stderr);

    console.log('\n=== DB COLUMNS CHECK ===');
    const db = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "DESCRIBE workers;" 2>/dev/null');
    console.log(db.stdout);

    console.log('\n=== UPTIME CHECK ===');
    const up = await ssh.execCommand('pm2 describe task-engine-api | grep -E "status|uptime|restart"');
    console.log(up.stdout);

    ssh.dispose();
  } catch (err) {
    console.error('Error:', err.message);
    ssh.dispose();
  }
})();
