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

  const [nullUsers] = await pool.query("SELECT COUNT(*) as c FROM workers WHERE user_id IS NULL OR user_id = ''");
  console.log('Workers with NULL or empty user_id:', nullUsers[0].c);

  const [totalWorkers] = await pool.query("SELECT COUNT(*) as c FROM workers");
  console.log('Total workers in table:', totalWorkers[0].c);

  const [indexes] = await pool.query("SHOW INDEX FROM workers");
  console.log('Indexes on workers table:', indexes.map(i => ({ key_name: i.Key_name, column_name: i.Column_name, non_unique: i.Non_unique })));

  await pool.end();
}

run().then(() => process.exit(0)).catch(e => { console.error(e); process.exit(1); });
    `;

    await ssh.execCommand("cat << 'EOF' > /root/check_null_workers.js\n" + script + "\nEOF");
    const res = await ssh.execCommand('NODE_PATH=/opt/task-engine/node_modules node /root/check_null_workers.js');
    console.log(res.stdout);
    if (res.stderr) console.error(res.stderr);

    ssh.dispose();
  } catch (e) {
    console.error(e);
  }
})();
