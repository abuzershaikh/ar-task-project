const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });

  console.log('=== History of Task 33d85448-d7c3-47bf-8c1a-aed201ef4b22 ===');
  const q1 = `SELECT id, task_id, worker_id, attempt_number, status, release_reason, assigned_at, accepted_at, expired_at FROM task_assignments WHERE task_id='33d85448-d7c3-47bf-8c1a-aed201ef4b22' ORDER BY attempt_number ASC;`;
  const r1 = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "${q1}"`);
  console.log(r1.stdout);

  console.log('=== Current state of Task 33d85448-d7c3-47bf-8c1a-aed201ef4b22 in tasks table ===');
  const q2 = `SELECT id, campaign_id, task_type, status, assigned_to, deadline, accepted_at, created_at, updated_at FROM tasks WHERE id='33d85448-d7c3-47bf-8c1a-aed201ef4b22';`;
  const r2 = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "${q2}"`);
  console.log(r2.stdout);

  console.log('=== History of Task 77ac34ec-9869-4dbd-b07c-0d601bc8a40f ===');
  const q3 = `SELECT id, task_id, worker_id, attempt_number, status, release_reason, assigned_at, accepted_at, expired_at FROM task_assignments WHERE task_id='77ac34ec-9869-4dbd-b07c-0d601bc8a40f' ORDER BY attempt_number ASC;`;
  const r3 = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "${q3}"`);
  console.log(r3.stdout);

  console.log('=== Current state of Task 77ac34ec-9869-4dbd-b07c-0d601bc8a40f in tasks table ===');
  const q4 = `SELECT id, campaign_id, task_type, status, assigned_to, deadline, accepted_at, created_at, updated_at FROM tasks WHERE id='77ac34ec-9869-4dbd-b07c-0d601bc8a40f';`;
  const r4 = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "${q4}"`);
  console.log(r4.stdout);

  process.exit(0);
}

run().catch(console.error);
