const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function checkRecentLogs() {
    await ssh.connect({
      host: '95.179.178.6',
      username: 'root',
      password: 'i_G72#y}(6gACDDU'
    });
    console.log('Connected to VPS...\n');

    console.log('--- LAST 50 LINES OF OUT LOG (Requests & Responses) ---');
    const outLog = await ssh.execCommand('tail -n 50 /root/.pm2/logs/task-engine-out-0.log');
    console.log(outLog.stdout);

    console.log('\n--- LAST 50 LINES OF ERROR LOG ---');
    const errorLog = await ssh.execCommand('tail -n 50 /root/.pm2/logs/task-engine-error-0.log');
    console.log(errorLog.stdout || '(No Errors)');

    ssh.dispose();
}

checkRecentLogs().catch(err => console.error(err));
