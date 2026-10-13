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

  console.log('=== DUPLICATE USER_ID IN WORKERS TABLE ===');
  const [dupWorkers] = await pool.query(\`
    SELECT user_id, COUNT(*) as cnt 
    FROM workers 
    WHERE user_id IS NOT NULL AND user_id != ''
    GROUP BY user_id 
    HAVING cnt > 1 
    ORDER BY cnt DESC
  \`);
  console.log('Found', dupWorkers.length, 'users with duplicate workers rows:');
  console.log(dupWorkers);

  console.log('=== DETAILS OF ALL WORKER ROWS FOR Naxm Glitch (IbVCmqFNdIYqbNYWUUsCKNFViQm1) ===');
  const [rows] = await pool.query(\`
    SELECT * FROM workers WHERE user_id = 'IbVCmqFNdIYqbNYWUUsCKNFViQm1'
  \`);
  console.log(rows);

  await pool.end();
}

run().then(() => process.exit(0)).catch(e => { console.error(e); process.exit(1); });
    `;

    await ssh.execCommand("cat << 'EOF' > /root/check_worker_dups.js\n" + script + "\nEOF");
    const res = await ssh.execCommand('NODE_PATH=/opt/task-engine/node_modules node /root/check_worker_dups.js');
    console.log(res.stdout);
    if (res.stderr) console.error(res.stderr);

    ssh.dispose();
  } catch (e) {
    console.error(e);
  }
})();
