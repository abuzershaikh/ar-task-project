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

  const [rows] = await conn.execute("SELECT id, name, code, category, service_type, is_active, link_field_label, link_field_placeholder FROM service_catalog WHERE name LIKE '%Google%' OR name LIKE '%Map%' OR category LIKE '%Map%' OR category LIKE '%Business%' OR code LIKE '%MAP%' OR code LIKE '%GMB%'");
  console.log('--- GOOGLE MAPS SERVICES ---');
  for (const r of rows) {
    console.log(r);
  }

  await conn.end();
}
test().catch(console.error);
`;

  await ssh.execCommand("cat << 'EOF' > /tmp/check_services.js\n" + script + "\nEOF");
  const res = await ssh.execCommand('node /tmp/check_services.js');
  console.log(res.stdout);
  if (res.stderr) console.error('STDERR:', res.stderr);
  ssh.dispose();
}

run().catch(console.error);
