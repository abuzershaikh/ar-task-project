const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== TASK SUBMISSIONS RECENT ===');
    const subs = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, task_id, worker_id, status, created_at FROM task_submissions ORDER BY created_at DESC LIMIT 5;"');
    console.log(subs.stdout || subs.stderr);

    console.log('=== RECENT API LOGS (Last 20) ===');
    const apiLogs = await ssh.execCommand('tail -n 20 /root/.pm2/logs/task-engine-api-out-0.log');
    console.log(apiLogs.stdout || apiLogs.stderr);

  } catch (e) {
    console.error('Error:', e.message);
  } finally {
    ssh.dispose();
    process.exit(0);
  }
}

run();
