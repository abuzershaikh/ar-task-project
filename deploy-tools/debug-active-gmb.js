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
      t.id, t.order_id, t.task_type, t.status, t.assigned_to, 
      o.id as order_id_val, o.status as order_status, o.title
    FROM tasks t
    LEFT JOIN orders o ON o.id = t.order_id
    WHERE (t.task_type LIKE '%GOOGLE%' OR t.task_type LIKE '%MAP%')
      AND t.status = 'active'
    LIMIT 20;
  `;
  const res = await ssh.execCommand(`mysql task_platform -e "${query}"`);
  console.log('=== ACTIVE GOOGLE TASKS ===\n', res.stdout);

  ssh.dispose();
}

run().catch(console.error);
