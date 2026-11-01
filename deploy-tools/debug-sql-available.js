const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 15000,
  });

  const query = `
    SELECT 
      t.id, t.order_id, t.task_type, t.status as task_status, t.assigned_to, 
      o.id as order_exists, o.status as order_status, o.created_at
    FROM tasks t
    LEFT JOIN orders o ON o.id = t.order_id
    WHERE (t.task_type LIKE '%GOOGLE%' OR t.task_type LIKE '%MAP%')
    ORDER BY t.created_at DESC
    LIMIT 20;
  `;
  const res = await ssh.execCommand(`mysql task_platform -e "${query}"`);
  console.log('=== GOOGLE TASKS & THEIR ORDERS ===\n', res.stdout);

  // Let's also check if there are tasks where task.status IN ('active', 'ACTIVE') and (task.assigned_to IS NULL or task.assigned_to = '')
  const query2 = `
    SELECT 
      t.id, t.order_id, t.task_type, t.status, t.assigned_to, o.status as order_status
    FROM tasks t
    LEFT JOIN orders o ON o.id = t.order_id
    WHERE (t.task_type LIKE '%GOOGLE%' OR t.task_type LIKE '%MAP%')
      AND t.status IN ('active', 'ACTIVE')
      AND (t.assigned_to IS NULL OR t.assigned_to = '')
      AND (o.id IS NULL OR o.status IN ('ACTIVE', 'active', 'IN_PROGRESS', 'in_progress'))
    LIMIT 20;
  `;
  const res2 = await ssh.execCommand(`mysql task_platform -e "${query2}"`);
  console.log('=== MATCHING TASKS ACCORDING TO REPO QUERY ===\n', res2.stdout);

  ssh.dispose();
}

run().catch(console.error);
