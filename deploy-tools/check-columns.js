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

  const [ouCols] = await conn.execute("SHOW COLUMNS FROM order_units LIKE 'target_url'");
  console.log('order_units target_url:', ouCols);

  const [taskCols] = await conn.execute("SHOW COLUMNS FROM tasks LIKE 'target_url'");
  console.log('tasks target_url:', taskCols);

  const [orderCols] = await conn.execute("SHOW COLUMNS FROM orders LIKE 'target_url'");
  console.log('orders target_url:', orderCols);

  // Check the two failed orders: '83e113c4-505f-4d6a-86f6-a41470cd91ae' and '302a200e-9a66-4846-a24c-15fb5b05b771'
  const [failedOrders] = await conn.execute("SELECT id, title, service_code, requirements, created_at FROM orders WHERE id IN ('83e113c4-505f-4d6a-86f6-a41470cd91ae', '302a200e-9a66-4846-a24c-15fb5b05b771')");
  console.log('\\n--- FAILED ORDERS IN DB ---');
  for (const o of failedOrders) {
    console.log(o);
  }

  await conn.end();
}
test().catch(console.error);
`;

  await ssh.execCommand("cat << 'EOF' > /tmp/check_columns.js\n" + script + "\nEOF");
  const res = await ssh.execCommand('node /tmp/check_columns.js');
  console.log(res.stdout);
  if (res.stderr) console.error('STDERR:', res.stderr);
  ssh.dispose();
}

run().catch(console.error);
