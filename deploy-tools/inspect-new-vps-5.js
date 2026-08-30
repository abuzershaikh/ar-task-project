const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function inspect5() {
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

    await run('FIREWALL RULES', 'firewall-cmd --list-all');
    await run('PHP-FPM STATUS & WEBSITES', 'systemctl status php-fpm || echo "No php-fpm"');

  } catch (err) {
    console.error('Inspection failed:', err);
  } finally {
    ssh.dispose();
  }
}

inspect5();
