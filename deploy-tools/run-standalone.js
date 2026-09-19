const { NodeSSH } = require('node-ssh');
const path = require('path');
const ssh = new NodeSSH();

async function run() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    await ssh.putFile(
      path.join(__dirname, 'standalone-audit.js'),
      '/opt/task-engine/run_audit_now.js'
    );

    const res = await ssh.execCommand('node run_audit_now.js', {
      cwd: '/opt/task-engine',
    });
    console.log(res.stdout);
    if (res.stderr) console.error('STDERR:', res.stderr);
  } catch (e) {
    console.error(e);
  } finally {
    ssh.dispose();
  }
}

run();
