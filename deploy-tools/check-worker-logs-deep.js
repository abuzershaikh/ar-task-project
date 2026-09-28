const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== WORKER PROCESS LOGS (Last 30) ===');
    const workerLogs = await ssh.execCommand('tail -n 30 /root/.pm2/logs/task-engine-worker-out-1.log');
    console.log(workerLogs.stdout || workerLogs.stderr);

    console.log('=== WORKER PROCESS ERROR LOGS (Last 30) ===');
    const workerErrLogs = await ssh.execCommand('tail -n 30 /root/.pm2/logs/task-engine-worker-error-1.log');
    console.log(workerErrLogs.stdout || workerErrLogs.stderr);

  } catch (e) {
    console.error('Error:', e.message);
  } finally {
    ssh.dispose();
    process.exit(0);
  }
}

run();
