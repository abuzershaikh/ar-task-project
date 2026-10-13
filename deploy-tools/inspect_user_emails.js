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

  const [indexes] = await pool.query("SHOW INDEX FROM users");
  console.log('Indexes on users table:', indexes.map(i => ({ key_name: i.Key_name, column_name: i.Column_name, non_unique: i.Non_unique })));

  const [dupEmails] = await pool.query(\`
    SELECT LOWER(TRIM(email)) as clean_email, COUNT(*) as cnt 
    FROM users 
    WHERE email IS NOT NULL AND email != ''
    GROUP BY clean_email 
    HAVING cnt > 1
  \`);
  console.log('Duplicate emails in users table:', dupEmails);

  await pool.end();
}

run().then(() => process.exit(0)).catch(e => { console.error(e); process.exit(1); });
    `;

    await ssh.execCommand("cat << 'EOF' > /root/check_user_emails.js\n" + script + "\nEOF");
    const res = await ssh.execCommand('NODE_PATH=/opt/task-engine/node_modules node /root/check_user_emails.js');
    console.log(res.stdout);
    if (res.stderr) console.error(res.stderr);

    ssh.dispose();
  } catch (e) {
    console.error(e);
  }
})();
