const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  const orderId = '732cbd88-15bb-4233-bf46-4a32ebc9df0e';

  console.log('=== 1. FULL ORDER DETAILS ===');
  const orderDetails = await ssh.execCommand(`mysql -u taskapp -p'taskapp_password' task_platform -e "SELECT * FROM orders WHERE id='${orderId}'\\G"`);
  console.log(orderDetails.stdout);

  console.log('=== 2. ORDER UNITS SUMMARY (STATUS COUNT) ===');
  const ouSummary = await ssh.execCommand(`mysql -u taskapp -p'taskapp_password' task_platform -e "SELECT status, COUNT(*) as count FROM order_units WHERE order_id='${orderId}' GROUP BY status;"`);
  console.log(ouSummary.stdout);

  console.log('=== 3. SAMPLE ORDER UNITS (FIRST 5 WITH COMMENTS / PAYLOAD) ===');
  const ouSamples = await ssh.execCommand(`mysql -u taskapp -p'taskapp_password' task_platform -e "SELECT id, unit_index, status, worker_id, comment, suggested_comment, custom_comment, created_at, updated_at FROM order_units WHERE order_id='${orderId}' LIMIT 5\\G"`);
  console.log(ouSamples.stdout);

  console.log('=== 4. DISTINCT COMMENTS IN ORDER UNITS ===');
  const ouComments = await ssh.execCommand(`mysql -u taskapp -p'taskapp_password' task_platform -e "SELECT DISTINCT comment, suggested_comment, custom_comment FROM order_units WHERE order_id='${orderId}' LIMIT 15;"`);
  console.log(ouComments.stdout);

  console.log('=== 5. TASKS TABLE (COUNT & STATUS) ===');
  const taskCount = await ssh.execCommand(`mysql -u taskapp -p'taskapp_password' task_platform -e "SELECT status, COUNT(*) as count FROM tasks WHERE order_id='${orderId}' GROUP BY status;"`);
  console.log(taskCount.stdout);

  console.log('=== 6. TASKS ASSIGNED / WORKING / SUBMITTED ===');
  const taskSample = await ssh.execCommand(`mysql -u taskapp -p'taskapp_password' task_platform -e "SELECT id, status, worker_id, comment, suggested_comment, created_at, updated_at FROM tasks WHERE order_id='${orderId}' AND (worker_id IS NOT NULL OR status != 'AVAILABLE') LIMIT 10\\G"`);
  console.log(taskSample.stdout);

  console.log('=== 7. TASK SUBMISSIONS (WORKERS WHO ACTUALLY WORKED / SUBMITTED) ===');
  const subCount = await ssh.execCommand(`mysql -u taskapp -p'taskapp_password' task_platform -e "SELECT ts.id, ts.worker_id, u.email as worker_email, u.full_name as worker_name, ts.status, ts.created_at FROM task_submissions ts LEFT JOIN users u ON ts.worker_id=u.id WHERE ts.order_id='${orderId}' OR ts.task_id IN (SELECT id FROM tasks WHERE order_id='${orderId}') LIMIT 20;"`);
  console.log(subCount.stdout);

  console.log('=== 8. LOGS FOR THIS ORDER ACTIVATION & NOTIFICATIONS IN PM2 ===');
  const pm2Logs = await ssh.execCommand(`grep -i "${orderId}" /root/.pm2/logs/task-engine-api-out-0.log | tail -n 50`);
  console.log(pm2Logs.stdout);

  console.log('=== 9. ANY ERRORS FOR THIS ORDER IN PM2 LOGS ===');
  const pm2Err = await ssh.execCommand(`grep -i "${orderId}" /root/.pm2/logs/task-engine-api-error-0.log | tail -n 30`);
  console.log(pm2Err.stdout);

  ssh.dispose();
}

run();
