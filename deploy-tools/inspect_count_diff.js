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

  const [countRaw] = await pool.query(\`
    SELECT COUNT(*) as cnt
    FROM support_conversations c
    LEFT JOIN users u ON (u.id = c.worker_id OR (c.worker_email != '' AND u.email = c.worker_email))
    LEFT JOIN workers w ON (w.user_id = u.id OR w.user_id = c.worker_id OR w.id = c.worker_id)
  \`);
  console.log('Total rows returned by current query with joins:', countRaw[0].cnt);

  const [countDistinct] = await pool.query(\`
    SELECT COUNT(DISTINCT c.id) as cnt
    FROM support_conversations c
  \`);
  console.log('Distinct conversations count:', countDistinct[0].cnt);

  await pool.end();
}

run().then(() => process.exit(0)).catch(e => { console.error(e); process.exit(1); });
    `;

    await ssh.execCommand("cat << 'EOF' > /root/check_count_diff.js\n" + script + "\nEOF");
    const res = await ssh.execCommand('NODE_PATH=/opt/task-engine/node_modules node /root/check_count_diff.js');
    console.log(res.stdout);
    if (res.stderr) console.error(res.stderr);

    ssh.dispose();
  } catch (e) {
    console.error(e);
  }
})();
