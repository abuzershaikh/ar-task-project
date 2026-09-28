const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== GREP ERROR OR EXCEPTION IN LOGS ===');
    const grep = await ssh.execCommand('grep -iE "error|exception|fail" /root/.pm2/logs/task-engine-api-error-0.log | tail -n 25');
    console.log(grep.stdout || grep.stderr);

    console.log('=== GREP 500 IN API OUT LOG ===');
    const grep500 = await ssh.execCommand('grep " 500 " /root/.pm2/logs/task-engine-api-out-0.log | tail -n 20');
    console.log(grep500.stdout || 'No 500 errors found in current log');

  } catch (e) {
    console.error('Error:', e.message);
  } finally {
    ssh.dispose();
    process.exit(0);
  }
}

run();
