const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
      readyTimeout: 60000,
    });

    const taskId = 'e8937ea1-e8a3-47e4-b64e-775d595a0661';

    console.log('=== TASK DETAILS ===');
    const t = await ssh.execCommand(`mysql -e 'SELECT id, title, order_id, task_type, reward, status, created_at FROM task_platform.tasks WHERE id = "${taskId}";'`);
    console.log(t.stdout);

    console.log('=== ORDER FOR THIS TASK ===');
    const o = await ssh.execCommand(`mysql -e 'SELECT o.id, o.buyer_id, u.email as buyer_email, o.title, o.task_type, o.reward_per_task, o.created_at FROM task_platform.tasks t JOIN task_platform.orders o ON t.order_id = o.id LEFT JOIN task_platform.users u ON o.buyer_id = u.id WHERE t.id = "${taskId}";'`);
    console.log(o.stdout);

    console.log('=== WHO APPROVED IT (PZxQCgtXW0hPflGEXM98zLaQNKQ2)? ===');
    const reviewer = await ssh.execCommand(`mysql -e 'SELECT id, email, role, created_at FROM task_platform.users WHERE id = "PZxQCgtXW0hPflGEXM98zLaQNKQ2";'`);
    console.log(reviewer.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

run();
