const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  const script = `
const fs = require('fs');
const envContent = fs.readFileSync('/opt/task-engine/.env', 'utf8');
const env = {};
envContent.split('\\n').forEach(line => {
  const m = line.match(/^([^=]+)=(.*)$/);
  if (m) env[m[1].trim()] = m[2].trim().replace(/^['"]|['"]$/g, '');
});

const mysql = require('/opt/task-engine/node_modules/mysql2/promise');

async function test() {
  const conn = await mysql.createConnection({
    host: env.DB_HOST || 'localhost',
    user: env.DB_USERNAME || env.DB_USER || 'root',
    password: env.DB_PASSWORD,
    database: env.DB_DATABASE || env.DB_NAME || 'task_engine',
    port: Number(env.DB_PORT) || 3306
  });

  const [tasks] = await conn.execute("SELECT id, order_id, task_type, status, created_at, requirements FROM tasks WHERE order_id = '302a200e-9a66-4846-a24c-15fb5b05b771'");
  console.log('Tasks created in DB:', tasks.length);
  for (const t of tasks) {
    console.log('------------------------------');
    console.log('Task ID:', t.id, 'Status:', t.status, 'Type:', t.task_type);
    const req = typeof t.requirements === 'string' ? JSON.parse(t.requirements) : t.requirements;
    console.log('TargetUrl:', req?.targetUrl);
    console.log('AppName:', req?.appName);
    console.log('Platform:', req?.platform);
  }

  await conn.end();
}
test().catch(console.error);
`;

  await ssh.execCommand("cat << 'EOF' > /tmp/verify_created_tasks.js\n" + script + "\nEOF");
  const res = await ssh.execCommand('node /tmp/verify_created_tasks.js');
  console.log(res.stdout);
  ssh.dispose();
}

run().catch(console.error);
