const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function checkLive() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
      readyTimeout: 10000,
    });
    const ps = await ssh.execCommand('ps aux | grep -E "node|nest|create_admin|pm2"');
    console.log('Running processes:\n', ps.stdout);
    const pm = await ssh.execCommand('pm2 list');
    console.log('PM2 List:\n', pm.stdout);
  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}
checkLive();
