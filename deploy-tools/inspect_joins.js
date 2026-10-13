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

  const query = \`
      SELECT c.id as conv_id, c.worker_id as conv_worker_id, c.worker_name as conv_worker_name,
             u.id as user_id, u.email as user_email,
             w.id as worker_table_id, w.user_id as worker_user_id
      FROM support_conversations c
      LEFT JOIN users u ON (u.id = c.worker_id OR (c.worker_email != '' AND u.email = c.worker_email))
      LEFT JOIN workers w ON (w.user_id = u.id OR w.user_id = c.worker_id OR w.id = c.worker_id)
      WHERE c.worker_email = 'workinhomex@gmail.com' OR c.worker_name LIKE '%Naxm%'
  \`;

  const [rows] = await pool.query(query);
  console.log('Query returned', rows.length, 'rows for Naxm Glitch!');
  console.log(rows);

  console.log('=== USERS FOR workinhomex@gmail.com ===');
  const [users] = await pool.query("SELECT id, email, full_name FROM users WHERE email = 'workinhomex@gmail.com' OR id = 'IbVCmqFNdIYqbNYWUUsCKNFViQm1'");
  console.log(users);

  console.log('=== WORKERS FOR user_id or worker_id ===');
  const [workers] = await pool.query("SELECT id, user_id, full_name, phone FROM workers WHERE user_id = 'IbVCmqFNdIYqbNYWUUsCKNFViQm1' OR id = 'IbVCmqFNdIYqbNYWUUsCKNFViQm1' OR user_id IN (SELECT id FROM users WHERE email = 'workinhomex@gmail.com')");
  console.log(workers);

  await pool.end();
}

run().then(() => process.exit(0)).catch(e => { console.error(e); process.exit(1); });
    `;

    await ssh.execCommand("cat << 'EOF' > /root/check_joins.js\n" + script + "\nEOF");
    const res = await ssh.execCommand('NODE_PATH=/opt/task-engine/node_modules node /root/check_joins.js');
    console.log(res.stdout);
    if (res.stderr) console.error(res.stderr);

    ssh.dispose();
  } catch (e) {
    console.error(e);
  }
})();
