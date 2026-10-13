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

  console.log('=== DUPLICATE CONVERSATIONS BY WORKER_EMAIL ===');
  const [byEmail] = await pool.query(\`
    SELECT worker_email, worker_name, COUNT(*) as cnt 
    FROM support_conversations 
    WHERE worker_email IS NOT NULL AND worker_email != ''
    GROUP BY worker_email 
    HAVING cnt > 1 
    ORDER BY cnt DESC 
    LIMIT 20
  \`);
  console.log(byEmail);

  console.log('=== DUPLICATE CONVERSATIONS BY WORKER_ID ===');
  const [byId] = await pool.query(\`
    SELECT worker_id, worker_name, worker_email, COUNT(*) as cnt 
    FROM support_conversations 
    GROUP BY worker_id 
    HAVING cnt > 1 
    ORDER BY cnt DESC 
    LIMIT 20
  \`);
  console.log(byId);

  console.log('=== DETAILS FOR workinhomex@gmail.com ===');
  const [details] = await pool.query(\`
    SELECT id, worker_id, worker_name, worker_email, worker_phone, last_message_text, last_message_at, created_at, unread_admin_count, unread_worker_count
    FROM support_conversations 
    WHERE worker_email = 'workinhomex@gmail.com' OR worker_name LIKE '%Naxm%'
    ORDER BY last_message_at DESC
  \`);
  console.log('Found', details.length, 'records:');
  console.log(details);

  console.log('=== TOTAL CONVERSATIONS IN TABLE ===');
  const [tot] = await pool.query('SELECT COUNT(*) as total FROM support_conversations');
  console.log(tot[0]);

  await pool.end();
}

run().then(() => process.exit(0)).catch(e => { console.error(e); process.exit(1); });
    `;

    await ssh.execCommand("cat << 'EOF' > /root/check_dups.js\n" + script + "\nEOF");
    const res = await ssh.execCommand('NODE_PATH=/opt/task-engine/node_modules node /root/check_dups.js');
    console.log(res.stdout);
    if (res.stderr) console.error(res.stderr);

    ssh.dispose();
  } catch (e) {
    console.error(e);
  }
})();
