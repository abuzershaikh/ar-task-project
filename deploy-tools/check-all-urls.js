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

  const [cols] = await conn.execute("SELECT table_name, column_name, data_type, character_maximum_length FROM information_schema.columns WHERE table_schema = DATABASE() AND (column_name LIKE '%url%' OR column_name LIKE '%link%')");
  console.log('URL columns across task_engine:');
  for (const c of cols) {
    console.log((c.table_name || c.TABLE_NAME) + '.' + (c.column_name || c.COLUMN_NAME) + ' -> ' + (c.data_type || c.DATA_TYPE) + '(' + (c.character_maximum_length || c.CHARACTER_MAXIMUM_LENGTH) + ')');
  }

  await conn.end();
}
test().catch(console.error);
`;

  await ssh.execCommand("cat << 'EOF' > /tmp/check_all_urls.js\n" + script + "\nEOF");
  const res = await ssh.execCommand('node /tmp/check_all_urls.js');
  console.log(res.stdout);
  if (res.stderr) console.error('STDERR:', res.stderr);
  ssh.dispose();
}

run().catch(console.error);
