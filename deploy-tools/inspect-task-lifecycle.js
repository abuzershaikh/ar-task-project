const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function inspect() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });

    console.log('=== 1. System Settings ===');
    const settings = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "SELECT * FROM system_settings;"`);
    console.log(settings.stdout);

    console.log('=== 2. Recent Tasks (Last 20) ===');
    const tasks = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, status, task_type, order_id, campaign_id, assigned_to, assigned_at, accepted_at, deadline, created_at, updated_at FROM tasks ORDER BY updated_at DESC LIMIT 20;"`);
    console.log(tasks.stdout);

    console.log('=== 3. Campaign Worker Participations (Last 15) ===');
    const parts = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "SELECT * FROM campaign_worker_participations ORDER BY last_assigned_at DESC LIMIT 15;"`);
    console.log(parts.stdout);

    console.log('=== 4. Task Assignments (Last 15) ===');
    const assigns = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "SELECT * FROM task_assignments ORDER BY assigned_at DESC LIMIT 15;"`);
    console.log(assigns.stdout);

    console.log('=== 5. Search PM2 Logs for Timeout / Release / Expire ===');
    const pm2Grep = await ssh.execCommand(`grep -E "TIMEOUT|releaseWorkerFromTask|released back to active|EXPIRED" /root/.pm2/logs/task-engine-api-out.log /root/.pm2/logs/task-engine-api-error.log | tail -n 30`);
    console.log(pm2Grep.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

inspect();
