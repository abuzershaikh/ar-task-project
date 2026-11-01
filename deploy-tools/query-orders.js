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

  const [orders] = await conn.execute("SELECT id, title, status, service_code, requirements, created_at FROM orders WHERE requirements LIKE '%goo.gl%' OR requirements LIKE '%maps%' OR requirements LIKE '%Surat%' OR requirements LIKE '%8TsYLjAEEEpUYspq7%' ORDER BY created_at DESC LIMIT 10");
  console.log('Matching orders found:', orders.length);
  for (const o of orders) {
    console.log('----------------------------');
    console.log('Order ID:', o.id);
    console.log('Title:', o.title);
    console.log('Status:', o.status);
    console.log('ServiceCode:', o.service_code);
    console.log('CreatedAt:', o.created_at);
    console.log('Requirements:', typeof o.requirements === 'string' ? o.requirements : JSON.stringify(o.requirements));
  }

  await conn.end();
}
test().catch(console.error);
`;

  await ssh.execCommand("cat << 'EOF' > /tmp/check_maps_orders.js\n" + script + "\nEOF");
  const res = await ssh.execCommand('node /tmp/check_maps_orders.js');
  console.log(res.stdout);
  if (res.stderr) console.error('STDERR:', res.stderr);
  ssh.dispose();
}

run().catch(console.error);
