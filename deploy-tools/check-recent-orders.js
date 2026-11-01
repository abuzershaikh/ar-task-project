const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function checkRecentOrders() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  const queryScript = `
const mysql = require('mysql2/promise');
async function run() {
  const conn = await mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: process.env.DB_PASSWORD || 'StrongPassword123!',
    database: 'task_engine'
  });
  const [rows] = await conn.execute("SELECT id, title, taskType, serviceCode, requirements, createdAt FROM orders WHERE requirements LIKE '%maps%' OR requirements LIKE '%goo.gl%' OR requirements LIKE '%Surat%' ORDER BY createdAt DESC LIMIT 5");
  for (const r of rows) {
    console.log('--- ORDER ---');
    console.log('ID:', r.id);
    console.log('Title:', r.title);
    console.log('TaskType:', r.taskType);
    console.log('ServiceCode:', r.serviceCode);
    console.log('CreatedAt:', r.createdAt);
    console.log('Requirements:', typeof r.requirements === 'string' ? r.requirements : JSON.stringify(r.requirements));
  }

  const [tasks] = await conn.execute("SELECT id, orderId, status, requirements, createdAt FROM tasks WHERE requirements LIKE '%maps%' OR requirements LIKE '%goo.gl%' OR requirements LIKE '%Surat%' ORDER BY createdAt DESC LIMIT 5");
  console.log('\\n--- GENERATED TASKS --- count:', tasks.length);
  for (const t of tasks) {
    console.log('Task ID:', t.id, 'orderId:', t.orderId, 'status:', t.status);
    console.log('Requirements:', typeof t.requirements === 'string' ? t.requirements.slice(0, 300) : JSON.stringify(t.requirements).slice(0, 300));
  }

  await conn.end();
}
run().catch(console.error);
`;

  const res = await ssh.execCommand(`node -e "${queryScript.replace(/"/g, '\\"')}"`, { cwd: '/opt/task-engine' });
  console.log(res.stdout);
  if (res.stderr) console.error('STDERR:', res.stderr);

  ssh.dispose();
}

checkRecentOrders().catch(console.error);
