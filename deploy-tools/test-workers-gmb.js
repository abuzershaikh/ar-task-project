const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 15000,
  });

  const workers = [
    { email: 'sarifkathat2534@gmail.com', id: 'uDOYtmmJKza4DFnHV0NLIAhw18A3' },
    { email: 'amankatoghan08@gmail.com', id: 'kxc64wrJQEf7xaaU86MxgPgfquJ2' },
    { email: 'kasanasouravgouravkasana123@gmail.com', id: 'ecNyDXrENiUtcISueM8CSl7YLVn2' },
    { email: 'snapbizux@gmail.com', id: '15QuKnQDcwS5NLacLIQ8V8CElnA2' },
    { email: 'brandnew_worker@gmail.com', id: 'newworker999' }
  ];

  for (const w of workers) {
    const res = await ssh.execCommand(
      `curl -s -H "x-user-email: ${w.email}" -H "x-user-id: ${w.id}" -H "x-user-role: WORKER" http://127.0.0.1:3000/api/v1/worker/tasks/available`
    );
    const data = JSON.parse(res.stdout);
    const gmbTasks = (data.tasks || []).filter(t => t.taskType?.includes('GOOGLE') || t.requirements?.platform === 'google_business');
    console.log(`Worker ${w.email}: total available = ${data.tasks?.length}, GMB available = ${gmbTasks.length}`);
    if (gmbTasks.length > 0) {
      console.log(`  GMB Task IDs:`, gmbTasks.map(t => t.id));
    }
  }

  ssh.dispose();
}

run().catch(console.error);
