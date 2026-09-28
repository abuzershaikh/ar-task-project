const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  const orderId = '732cbd88-15bb-4233-bf46-4a32ebc9df0e';

  console.log('=== 1. TASKS WITH STATUS != active ===');
  const activeTasks = await ssh.execCommand(`mysql -u taskapp -p'taskapp_password' task_platform -e "SELECT id, status, worker_id, assigned_to, started_at, submitted_at, requirements FROM tasks WHERE order_id='${orderId}' AND status != 'active'\\G"`);
  console.log(activeTasks.stdout);

  console.log('=== 2. WORKERS WHO ACCEPTED OR SUBMITTED THESE TASKS ===');
  const workers = await ssh.execCommand(`mysql -u taskapp -p'taskapp_password' task_platform -e "SELECT u.id, u.email, u.full_name, u.phone, t.status as task_status, t.submitted_at FROM tasks t JOIN users u ON (t.worker_id = u.id OR t.assigned_to = u.id) WHERE t.order_id='${orderId}' AND t.status != 'active';"`);
  console.log(workers.stdout);

  console.log('=== 3. TASK SUBMISSIONS FOR THIS ORDER (PROOF & SCREENSHOTS) ===');
  const subs = await ssh.execCommand(`mysql -u taskapp -p'taskapp_password' task_platform -e "SELECT * FROM task_submissions WHERE order_id='${orderId}' OR task_id IN (SELECT id FROM tasks WHERE order_id='${orderId}')\\G"`);
  console.log(subs.stdout);

  console.log('=== 4. CHECK FCM NOTIFICATIONS SENT AT 11:50 AM ===');
  const fcmLog = await ssh.execCommand(`grep -E "11:50:|11:51:" /root/.pm2/logs/task-engine-api-out-0.log | grep -i -E "FCM|notification|OrderActivated|broadcast|send" | head -n 30`);
  console.log(fcmLog.stdout);

  console.log('=== 5. CHECK ANY EXCEPTION/ERRORS DURING CREATION OR DISPATCH ===');
  const errCheck = await ssh.execCommand(`grep -E "11:50:|11:51:" /root/.pm2/logs/task-engine-api-error-0.log | head -n 30`);
  console.log(errCheck.stdout ? errCheck.stdout : 'NO ERRORS in error-0.log at that time!');

  ssh.dispose();
}

run();
