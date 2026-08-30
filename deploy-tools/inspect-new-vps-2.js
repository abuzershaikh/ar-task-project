const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function inspect2() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
      readyTimeout: 30000,
    });

    async function run(title, cmd) {
      console.log(`=============================`);
      console.log(`>>> ${title}`);
      console.log(`Command: ${cmd}`);
      console.log(`=============================`);
      const res = await ssh.execCommand(cmd);
      if (res.stdout) console.log(res.stdout);
      if (res.stderr) console.error('STDERR:', res.stderr);
      console.log('');
    }

    await run('OS RELEASE', 'cat /etc/os-release');
    await run('MEMORY & CPU & DISK', 'free -h; echo "CPU Cores:"; nproc; echo "Disk:"; df -h');
    await run('NGINX CONF.D', 'ls -la /etc/nginx/conf.d/ 2>/dev/null; cat /etc/nginx/conf.d/*.conf 2>/dev/null');
    await run('NGINX MAIN CONF', 'cat /etc/nginx/nginx.conf');
    await run('REDIS INSTALL STATUS', 'which redis-server; systemctl status redis || systemctl status redis-server || echo "Redis service not found"');
    await run('EXISTING /opt FOLDERS', 'ls -la /opt/ 2>/dev/null');
    await run('EXISTING PM2 JSON / CONFIG', 'pm2 describe waziper-engine');
    await run('MARIADB / MYSQL VERSION & USERS', 'mysql -e "SELECT User, Host FROM mysql.user;" 2>/dev/null');

  } catch (err) {
    console.error('Inspection failed:', err);
  } finally {
    ssh.dispose();
  }
}

inspect2();
