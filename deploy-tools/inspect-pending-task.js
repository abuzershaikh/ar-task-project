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

    const pendingTaskId = 'df50e363-aa85-47e3-8198-3b8143c5bbf6';
    const res = await ssh.execCommand(`mysql -e 'SELECT o.id, o.title, o.reward_per_task, u.email as buyer_email FROM task_platform.tasks t JOIN task_platform.orders o ON t.order_id = o.id LEFT JOIN task_platform.users u ON o.buyer_id = u.id WHERE t.id = "${pendingTaskId}";'`);
    console.log('Pending Task Info:\n', res.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

run();
