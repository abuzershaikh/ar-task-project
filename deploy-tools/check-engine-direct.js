const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== ORDERS STATUS ===');
    const orders = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT status, count(*) as count FROM orders GROUP BY status;"');
    console.log(orders.stdout || orders.stderr);

    console.log('=== TASKS STATUS ===');
    const tasks = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT status, count(*) as count FROM tasks GROUP BY status;"');
    console.log(tasks.stdout || tasks.stderr);

    console.log('=== LATEST ORDER INFO ===');
    const latest = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, title, total_tasks_required, status, created_at FROM orders ORDER BY created_at DESC LIMIT 2;"');
    console.log(latest.stdout || latest.stderr);

    console.log('=== TASKS FOR LATEST ORDER ===');
    const orderTasks = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT status, count(*) as count FROM tasks WHERE order_id = (SELECT id FROM orders ORDER BY created_at DESC LIMIT 1) GROUP BY status;"');
    console.log(orderTasks.stdout || orderTasks.stderr);

    console.log('=== WORKER SUBMISSIONS (LAST 10) ===');
    const sub = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, task_id, worker_id, status, submitted_at FROM task_submissions ORDER BY submitted_at DESC LIMIT 10;"');
    console.log(sub.stdout || sub.stderr);

  } catch (e) {
    console.error('Error:', e.message);
  } finally {
    ssh.dispose();
    process.exit(0);
  }
}

run();
