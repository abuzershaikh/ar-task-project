const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });
    console.log('Running pm2 restart --update-env...');
    const res = await ssh.execCommand('pm2 restart task-engine-api --update-env');
    console.log(res.stdout);
    
    // Quick test: curl the endpoint or check logs
    const logRes = await ssh.execCommand('pm2 logs task-engine-api --lines 15 --nostream');
    console.log('Recent logs:\n', logRes.stdout);
  } catch (e) {
    console.error(e);
  } finally {
    ssh.dispose();
  }
}
run();
