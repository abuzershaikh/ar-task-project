const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== PM2 LIST ===');
    const pm2List = await ssh.execCommand('pm2 list');
    console.log(pm2List.stdout || pm2List.stderr);

    console.log('\n=== CURL LOCALHOST:3000 HEALTH ===');
    const curl = await ssh.execCommand('curl -i -s http://127.0.0.1:3000/api/v1/health || curl -i -s http://127.0.0.1:3000/');
    console.log(curl.stdout || curl.stderr);

    console.log('\n=== PM2 LOGS (Last 30 lines) ===');
    const logs = await ssh.execCommand('pm2 logs --lines 30 --nostream');
    console.log(logs.stdout || logs.stderr);

  } catch (e) {
    console.error('SSH Error:', e.message);
  } finally {
    ssh.dispose();
    process.exit(0);
  }
}

run();
