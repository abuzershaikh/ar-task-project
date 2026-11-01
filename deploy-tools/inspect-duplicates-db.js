const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 15000,
  });

  console.log('--- 1. Recent GMB & Play Store tasks in tasks table ---');
  const res = await ssh.execCommand(
    `mysql task_platform -e "SELECT id, order_id, platform, task_type, status, assigned_to, LEFT(requirements, 300) AS reqs FROM tasks WHERE platform IN ('google_business', 'playstore', 'app') OR task_type LIKE '%PLAY%' OR task_type LIKE '%GMB%' OR task_type LIKE '%GOOGLE%' ORDER BY created_at DESC LIMIT 15;"`
  );
  console.log(res.stdout);

  console.log('\n--- 2. Check worker_completed_identities table structure & rows ---');
  const res2 = await ssh.execCommand(
    `mysql task_platform -e "DESCRIBE worker_completed_identities; SELECT * FROM worker_completed_identities ORDER BY id DESC LIMIT 10;"`
  );
  console.log(res2.stdout || res2.stderr);

  console.log('\n--- 3. Check duplicate assignments on same package or URL in DB ---');
  const res3 = await ssh.execCommand(
    `mysql task_platform -e "SELECT assigned_to, COUNT(*) as cnt, JSON_UNQUOTE(JSON_EXTRACT(requirements, '$.targetUrl')) as url, JSON_UNQUOTE(JSON_EXTRACT(requirements, '$.packageId')) as pkg FROM tasks WHERE assigned_to IS NOT NULL AND status IN ('completed', 'submitted', 'under_review', 'assigned', 'in_progress', 'accepted') GROUP BY assigned_to, url, pkg HAVING cnt > 1 LIMIT 20;"`
  );
  console.log(res3.stdout);

  ssh.dispose();
}

run().catch(console.error);
