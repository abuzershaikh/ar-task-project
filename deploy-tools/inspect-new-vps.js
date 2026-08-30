const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function inspect() {
  try {
    console.log('Connecting to 65.20.77.112...');
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
      readyTimeout: 30000,
    });
    console.log('SSH Connected Successfully!\n');

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

    await run('OS & UPTIME', 'uname -a && uptime');
    await run('HARDWARE RESOURCES (RAM & CPU & DISK)', 'free -h && nproc && df -h /');
    await run('LISTENING PORTS & ACTIVE SERVICES', 'ss -tulpn || netstat -tulpn');
    await run('PM2 RUNNING PROCESSES', 'pm2 list || which pm2 || echo "No PM2"');
    await run('SYSTEMD RUNNING SERVICES (NODE/NGINX/ETC)', 'systemctl list-units --type=service --state=running | grep -E "node|pm2|nginx|caddy|mysql|mariadb|redis|docker|apache" || true');
    await run('DIRECTORIES IN /var/www', 'ls -la /var/www/ 2>/dev/null || echo "No /var/www"');
    await run('DIRECTORIES IN /root', 'ls -la /root/ 2>/dev/null');
    await run('DIRECTORIES IN /home', 'ls -la /home/ 2>/dev/null');
    await run('INSTALLED RUNTIMES (NODE, NPM, PYTHON, DOCKER)', 'node -v 2>/dev/null; npm -v 2>/dev/null; docker -v 2>/dev/null; pm2 -v 2>/dev/null');
    await run('DATABASE CHECK (MYSQL / REDIS)', 'mysql -e "SHOW DATABASES;" 2>/dev/null || echo "MySQL not passwordless root"; redis-cli ping 2>/dev/null || echo "Redis ping failed"');
    await run('NGINX SITES / CADDY CONFIGS', 'ls -la /etc/nginx/sites-enabled/ 2>/dev/null || true; ls -la /etc/caddy/ 2>/dev/null || true');

  } catch (err) {
    console.error('Inspection failed:', err);
  } finally {
    ssh.dispose();
  }
}

inspect();
