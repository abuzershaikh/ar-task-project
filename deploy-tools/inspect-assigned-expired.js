const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });

  // 1. Check all tasks where assigned_to IS NOT NULL and status IN ('assigned', 'accepted', 'in_progress')
  const sql = "SELECT id, campaign_id, task_type, status, assigned_to, deadline, accepted_at, created_at FROM tasks WHERE status IN ('assigned', 'accepted', 'in_progress');";
  const res = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "${sql}"`);
  console.log('Currently Assigned/Accepted Tasks:\n', res.stdout);

  // 2. Check campaign_worker_participation with status EXPIRED
  const sql2 = "SELECT id, campaign_id, worker_id, status, created_at FROM campaign_worker_participation WHERE status='EXPIRED';";
  const res2 = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "${sql2}"`);
  console.log('Expired Participations:\n', res2.stdout);

  // 3. Check early released task assignments
  const sql3 = "SELECT id, task_id, worker_id, status, release_reason, expired_at FROM task_assignments WHERE status='EARLY_RELEASED';";
  const res3 = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "${sql3}"`);
  console.log('Early Released Assignments:\n', res3.stdout);

  process.exit(0);
}

run().catch(console.error);
