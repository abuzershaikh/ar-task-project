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

    console.log('\n--- PM2 PROCESS LIST ---');
    const pm2Status = await ssh.execCommand('pm2 status');
    console.log(pm2Status.stdout || pm2Status.stderr);

    console.log('\n--- LAST 30 LINES OF PM2 LOGS ---');
    const pm2Logs = await ssh.execCommand('pm2 logs task-engine --lines 30 --raw');
    console.log(pm2Logs.stdout || pm2Logs.stderr);

  } catch (err) {
    console.error('Inspection failed:', err);
  } finally {
    ssh.dispose();
  }
}

inspectVps();
