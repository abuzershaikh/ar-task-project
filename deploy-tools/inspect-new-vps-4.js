const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function inspect4() {
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

    await run('FORM ENGINE .ENV', 'cat /opt/form_engine/.env');
    await run('FORM ENGINE PACKAGE.JSON', 'cat /opt/form_engine/package.json');
    await run('FIREWALL STATUS (FIREWALLD / UFW / IPTABLES)', 'systemctl status firewalld 2>&1 || ufw status 2>&1');

  } catch (err) {
    console.error('Inspection failed:', err);
  } finally {
    ssh.dispose();
  }
}

inspect4();
