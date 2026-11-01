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

  const [t1] = await conn.execute("SELECT count(*) as count FROM tasks WHERE order_id = '83e113c4-505f-4d6a-86f6-a41470cd91ae'");
  const [t2] = await conn.execute("SELECT count(*) as count FROM tasks WHERE order_id = '302a200e-9a66-4846-a24c-15fb5b05b771'");
  console.log('Order 83e113c4 tasks count:', t1[0].count);
  console.log('Order 302a200e tasks count:', t2[0].count);

  await conn.end();
}
test().catch(console.error);
`;

  await ssh.execCommand("cat << 'EOF' > /tmp/check_failed_counts.js\n" + script + "\nEOF");
  const res = await ssh.execCommand('node /tmp/check_failed_counts.js');
  console.log(res.stdout);
  if (res.stderr) console.error('STDERR:', res.stderr);
  ssh.dispose();
}

run().catch(console.error);
