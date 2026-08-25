const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function inspectVps() {
  try {
    console.log('Connecting to VPS to check current running server status...');
    await ssh.connect({
      host: '95.179.178.6',
      username: 'root',
      password: 'i_G72#y}(6gACDDU',
      readyTimeout: 30000,
    });

    console.log('\n--- PM2 PROCESS DETAILS ---');
    const pm2Desc = await ssh.execCommand('pm2 describe 0');
    console.log(pm2Desc.stdout || pm2Desc.stderr);

    console.log('\n--- DIRECTORY CONTENT ---');
    const lsRes = await ssh.execCommand('ls -la /var/www/task-engine');
    console.log(lsRes.stdout || lsRes.stderr);

  } catch (err) {
    console.error('Inspection failed:', err);
  } finally {
    ssh.dispose();
  }
}

inspectVps();
