const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });

  // Check what available tasks exist in the database right now (status='active' and assigned_to IS NULL)
  const q1 = `
    SELECT t.id, t.campaign_id, t.order_id, t.task_type, t.status, t.assigned_to, o.title, o.status as order_status
    FROM tasks t
    LEFT JOIN orders o ON o.id = t.order_id
    WHERE t.status IN ('active', 'ACTIVE')
      AND (t.assigned_to IS NULL OR t.assigned_to = '')
      AND (o.id IS NULL OR o.status IN ('ACTIVE', 'active', 'IN_PROGRESS', 'in_progress'))
    ORDER BY t.created_at DESC
    LIMIT 10;
  `;
  const r1 = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "${q1}"`);
  console.log('=== Unassigned Active Tasks in Pool ===\n', r1.stdout);

  // Check exclusions for sufieditz@gmail.com vs sonathe333@gmail.com
  const q2 = `
    SELECT campaign_id, status FROM campaign_worker_participation WHERE worker_id='sufieditz@gmail.com';
  `;
  const r2 = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "${q2}"`);
  console.log('=== Participations for sufieditz@gmail.com ===\n', r2.stdout);

  const q3 = `
    SELECT campaign_id, status FROM campaign_worker_participation WHERE worker_id='sonathe333@gmail.com';
  `;
  const r3 = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "${q3}"`);
  console.log('=== Participations for sonathe333@gmail.com ===\n', r3.stdout);

  process.exit(0);
}

run().catch(console.error);
