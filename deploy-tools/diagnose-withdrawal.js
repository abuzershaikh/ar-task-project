const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function main() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    const r = await ssh.execCommand('pm2 describe task-engine-api');
    console.log('PM2 describe:\n', r.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

main();
