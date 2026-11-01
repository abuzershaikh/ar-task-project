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

  const [cols] = await conn.execute("DESCRIBE task_assignments");
  console.log('task_assignments cols:', cols.map(c => c.Field + ' (' + c.Type + ')').join(', '));

  console.log('Altering order_units target_url to TEXT...');
  await conn.execute("ALTER TABLE order_units MODIFY COLUMN target_url TEXT NULL");
  console.log('Successfully altered order_units.target_url to TEXT!');

  const [ouCols] = await conn.execute("SHOW COLUMNS FROM order_units LIKE 'target_url'");
  console.log('Updated order_units target_url:', ouCols);

  await conn.end();
}
test().catch(console.error);
`;

  await ssh.execCommand("cat << 'EOF' > /tmp/migrate_target_url.js\n" + script + "\nEOF");
  const res = await ssh.execCommand('node /tmp/migrate_target_url.js');
  console.log(res.stdout);
  if (res.stderr) console.error('STDERR:', res.stderr);
  ssh.dispose();
}

run().catch(console.error);
