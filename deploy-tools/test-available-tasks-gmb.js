const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 15000,
  });

  // Test with brand new worker
  const res1 = await ssh.execCommand(
    'curl -s -H "x-user-email: brand_new_tester_999@gmail.com" -H "x-user-id: newtest999" -H "x-user-role: WORKER" http://127.0.0.1:3000/api/v1/worker/tasks/available'
  );
  const data1 = JSON.parse(res1.stdout);
  console.log('Brand new worker tasks count:', data1.tasks?.length);

  const googleTasksNew = (data1.tasks || []).filter(t => (t.taskType || '').includes('GOOGLE') || (t.taskType || '').includes('MAP'));
  console.log('Google tasks for brand new worker:', googleTasksNew.length);
  if (googleTasksNew.length > 0) {
    console.log('Sample Google task for brand new worker:', JSON.stringify(googleTasksNew[0], null, 2));
  }

  // Now test with an existing worker from DB:
  const workerRes = await ssh.execCommand(
    "mysql task_platform -e 'SELECT id, email FROM users WHERE role=\"WORKER\" ORDER BY created_at DESC LIMIT 5;'"
  );
  console.log('Recent workers:\n', workerRes.stdout);

  ssh.dispose();
}

run().catch(console.error);
