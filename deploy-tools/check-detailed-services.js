const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    const res = await ssh.execCommand('pm2 jlist');
    const list = JSON.parse(res.stdout);
    console.log('--- PM2 PROCESSES ---');
    list.forEach(p => {
      console.log(`ID: ${p.pm_id} | Name: ${p.name} | Status: ${p.pm2_env.status} | Restarts: ${p.pm2_env.restart_time} | Uptime: ${Math.round((Date.now() - p.pm2_env.pm_uptime)/1000)}s | Mem: ${Math.round(p.monit.memory/(1024*1024))}MB | CPU: ${p.monit.cpu}%`);
    });

    console.log('\n--- NGINX STATUS ---');
    const nginx = await ssh.execCommand('systemctl is-active nginx');
    console.log('Nginx is-active:', nginx.stdout.trim());

    console.log('\n--- MYSQL STATUS ---');
    const mysql = await ssh.execCommand('systemctl is-active mysql || systemctl is-active mariadb');
    console.log('MySQL is-active:', mysql.stdout.trim());

    console.log('\n--- REDIS STATUS ---');
    const redis = await ssh.execCommand('systemctl is-active redis || systemctl is-active redis-server');
    console.log('Redis is-active:', redis.stdout.trim());

    console.log('\n--- RECENT ERRORS (last 20 error lines) ---');
    const errLogs = await ssh.execCommand('tail -n 20 /root/.pm2/logs/task-engine-api-error-0.log /root/.pm2/logs/task-engine-worker-error-1.log 2>/dev/null');
    console.log(errLogs.stdout || errLogs.stderr);

  } catch (e) {
    console.error('Error:', e.message);
  } finally {
    ssh.dispose();
    process.exit(0);
  }
}

run();
