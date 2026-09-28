const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  const orderId = '732cbd88-15bb-4233-bf46-4a32ebc9df0e';

  console.log('=== ORDER UNITS COLUMNS ===');
  const ouCols = await ssh.execCommand("mysql -u taskapp -p'taskapp_password' task_platform -e 'DESCRIBE order_units;'");
  console.log(ouCols.stdout);

  console.log('=== TASKS COLUMNS ===');
  const taskCols = await ssh.execCommand("mysql -u taskapp -p'taskapp_password' task_platform -e 'DESCRIBE tasks;'");
  console.log(taskCols.stdout);

  console.log('=== ORDER UNITS DATA (SAMPLE 3) ===');
  const ouData = await ssh.execCommand(`mysql -u taskapp -p'taskapp_password' task_platform -e "SELECT * FROM order_units WHERE order_id='${orderId}' LIMIT 3\\G"`);
  console.log(ouData.stdout);

  console.log('=== TASKS DATA (SAMPLE 3) ===');
  const taskData = await ssh.execCommand(`mysql -u taskapp -p'taskapp_password' task_platform -e "SELECT * FROM tasks WHERE order_id='${orderId}' LIMIT 3\\G"`);
  console.log(taskData.stdout);

  console.log('=== 5 COMPLETED SUBMISSIONS (UNDER_REVIEW) ===');
  const subData = await ssh.execCommand(`mysql -u taskapp -p'taskapp_password' task_platform -e "SELECT * FROM task_submissions WHERE task_id IN (SELECT id FROM tasks WHERE order_id='${orderId}') OR order_id='${orderId}'\\G"`);
  console.log(subData.stdout);

  ssh.dispose();
}

run();
