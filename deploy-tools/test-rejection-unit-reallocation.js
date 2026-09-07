const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  console.log('Testing Task Rejection & Unit Re-allocation in MySQL on VPS...');

  // 1. Check current submission for task 6aab0f82-a75a-4757-bd73-06c950dab5fb
  const taskId = '6aab0f82-a75a-4757-bd73-06c950dab5fb';
  const subRes = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e 'SELECT id, task_id, worker_id, status FROM task_submissions WHERE task_id = "${taskId}" ORDER BY created_at DESC LIMIT 1;'`);
  console.log('Submission in DB:\n', subRes.stdout);

  // 2. Admin Login
  const loginRes = await ssh.execCommand(`curl -s -X POST http://localhost:3000/api/v1/auth/login -H "Content-Type: application/json" -d '{"email":"snapbizux@gmail.com","password":"80978097"}'`);
  const adminData = JSON.parse(loginRes.stdout);
  const adminToken = adminData.data?.accessToken;
  console.log('Admin Token:', adminToken ? 'YES' : 'NO');

  // Extract submission ID
  const subLines = subRes.stdout.trim().split('\n');
  if (subLines.length >= 2) {
    const subId = subLines[1].split('\t')[0].trim();
    console.log('Rejecting submission ID:', subId);

    // Reject submission via Review API
    const rejectRes = await ssh.execCommand(`curl -s -X POST http://localhost:3000/api/v1/admin/reviews/${subId}/reject -H "Authorization: Bearer ${adminToken}" -H "Content-Type: application/json" -d '{"reason":"Quality does not meet standard"}'`);
    console.log('Reject API Response:\n', rejectRes.stdout);

    // 3. Inspect task in MySQL after rejection
    const taskCheck = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e 'SELECT id, status, assigned_to, reward_amount FROM tasks WHERE id = "${taskId}";'`);
    console.log('Task state after rejection in MySQL:\n', taskCheck.stdout);

    // 4. Check if task appears in available tasks feed
    const availRes = await ssh.execCommand(`curl -s -X GET http://localhost:3000/api/v1/worker/tasks/available -H "Authorization: Bearer ${adminToken}"`);
    try {
      const availJson = JSON.parse(availRes.stdout);
      const isRequeued = availJson.tasks?.some(t => t.id === taskId);
      console.log('Is rejected task re-queued in available pool?:', isRequeued ? 'YES (PASS)' : 'Check status');
    } catch (_) {}
  }

  ssh.dispose();
}

run();
