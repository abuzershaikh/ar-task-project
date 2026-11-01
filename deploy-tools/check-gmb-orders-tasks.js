const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 30000,
  });

  console.log('--- 1. All Google Business Orders ---');
  const gmbOrders = await ssh.execCommand(`
    SELECT id, title, task_type, status, total_tasks_required, created_at,
           JSON_UNQUOTE(JSON_EXTRACT(requirements, '$.targetUrl')) as url,
           JSON_UNQUOTE(JSON_EXTRACT(requirements, '$.businessName')) as bName
    FROM orders
    WHERE task_type LIKE '%GOOGLE%' OR task_type LIKE '%GMB%'
    ORDER BY created_at DESC;
  `);
  console.log(gmbOrders.stdout);

  console.log('--- 2. All Google Business Tasks with assignments ---');
  const gmbTasks = await ssh.execCommand(`
    SELECT t.id, t.order_id, t.task_type, t.status, t.assigned_to, t.created_at,
           JSON_UNQUOTE(JSON_EXTRACT(t.requirements, '$.targetUrl')) as url,
           JSON_UNQUOTE(JSON_EXTRACT(t.requirements, '$.businessName')) as bName
    FROM tasks t
    WHERE t.task_type LIKE '%GOOGLE%' OR t.task_type LIKE '%GMB%'
    ORDER BY t.created_at DESC;
  `);
  console.log(gmbTasks.stdout);

  ssh.dispose();
}

run().catch(console.error);
