const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function checkLogs() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== PM2 STATUS ===');
    const pm2Status = await ssh.execCommand('pm2 status');
    console.log(pm2Status.stdout);

    console.log('=== PM2 RECENT LOGS (LAST 100 LINES) ===');
    const pm2Logs = await ssh.execCommand('pm2 logs --lines 100 --nostream');
    console.log(pm2Logs.stdout || pm2Logs.stderr);

    console.log('=== NGINX ACCESS LOG (LAST 50 LINES) ===');
    const nginxAccess = await ssh.execCommand('tail -n 50 /var/log/nginx/access.log');
    console.log(nginxAccess.stdout || nginxAccess.stderr);

    console.log('=== NGINX ERROR LOG (LAST 50 LINES) ===');
    const nginxErr = await ssh.execCommand('tail -n 50 /var/log/nginx/error.log');
    console.log(nginxErr.stdout || nginxErr.stderr);

  } catch (err) {
    console.error('SSH Error:', err.message);
  } finally {
    ssh.dispose();
    process.exit(0);
  }
}

checkLogs();
