const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 15000,
  });

  console.log('--- 1. Sample 5 Play Store tasks with assignments ---');
  const playSample = await ssh.execCommand(`
    SELECT t.id, t.order_id, t.task_type, t.status, t.assigned_to,
           JSON_UNQUOTE(JSON_EXTRACT(t.requirements, '$.targetUrl')) as url,
           JSON_UNQUOTE(JSON_EXTRACT(t.requirements, '$.packageId')) as pkg,
           JSON_UNQUOTE(JSON_EXTRACT(t.requirements, '$.appName')) as name
    FROM tasks t
    WHERE t.task_type LIKE '%PLAY%' AND t.assigned_to IS NOT NULL
    LIMIT 5;
  `);
  console.log(playSample.stdout);

  console.log('--- 2. Sample 5 Google Maps tasks with assignments ---');
  const gmbSample = await ssh.execCommand(`
    SELECT t.id, t.order_id, t.task_type, t.status, t.assigned_to,
           JSON_UNQUOTE(JSON_EXTRACT(t.requirements, '$.targetUrl')) as url,
           JSON_UNQUOTE(JSON_EXTRACT(t.requirements, '$.businessName')) as bName
    FROM tasks t
    WHERE t.task_type LIKE '%GOOGLE%' AND t.assigned_to IS NOT NULL
    LIMIT 5;
  `);
  console.log(gmbSample.stdout);

  console.log('--- 3. Check all orders for Play Store & Google Business ---');
  const orders = await ssh.execCommand(`
    SELECT id, task_type, status, total_tasks_required, created_at,
           JSON_UNQUOTE(JSON_EXTRACT(requirements, '$.targetUrl')) as url,
           JSON_UNQUOTE(JSON_EXTRACT(requirements, '$.packageId')) as pkg,
           JSON_UNQUOTE(JSON_EXTRACT(requirements, '$.businessName')) as bName
    FROM orders
    WHERE task_type LIKE '%PLAY%' OR task_type LIKE '%GOOGLE%' OR task_type LIKE '%GMB%'
    ORDER BY created_at DESC LIMIT 10;
  `);
  console.log(orders.stdout);

  ssh.dispose();
}

run().catch(console.error);
