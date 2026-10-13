const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

(async () => {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    const script = `
const mysql = require('mysql2/promise');

async function run() {
  const pool = await mysql.createPool({
    host: 'localhost',
    user: 'taskapp',
    password: 'taskapp_password',
    database: 'task_platform',
  });

  console.log('=== FOREIGN KEYS REFERENCING WORKERS TABLE ===');
  const [fks] = await pool.query(\`
    SELECT TABLE_NAME, COLUMN_NAME, CONSTRAINT_NAME, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME
    FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
    WHERE REFERENCED_TABLE_SCHEMA = 'task_platform' 
      AND REFERENCED_TABLE_NAME = 'workers'
  \`);
  console.log(fks);

  console.log('=== COLUMNS NAMED worker_id ACROSS ALL TABLES ===');
  const [cols] = await pool.query(\`
    SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'task_platform' 
      AND COLUMN_NAME LIKE '%worker%'
  \`);
  console.log(cols);

  await pool.end();
}

run().then(() => process.exit(0)).catch(e => { console.error(e); process.exit(1); });
    `;

    await ssh.execCommand("cat << 'EOF' > /root/check_fks.js\n" + script + "\nEOF");
    const res = await ssh.execCommand('NODE_PATH=/opt/task-engine/node_modules node /root/check_fks.js');
    console.log(res.stdout);
    if (res.stderr) console.error(res.stderr);

    ssh.dispose();
  } catch (e) {
    console.error(e);
  }
})();
