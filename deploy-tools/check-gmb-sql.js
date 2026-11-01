const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 30000,
  });

  const sql = `
    SELECT id, order_id, task_type, status, assigned_to, 
           SUBSTRING(requirements, 1, 150) as req_snippet
    FROM tasks 
    WHERE task_type = 'GOOGLE_BUSINESS_REVIEW' OR task_type = 'GOOGLE_BUSINESS_RATING'
    ORDER BY created_at DESC 
    LIMIT 20;
  `;
  
  await ssh.execCommand(`cat << 'EOF' > /tmp/check_gmb.sql\n${sql}\nEOF`);
  const res = await ssh.execCommand('mysql task_platform < /tmp/check_gmb.sql');
  console.log('Result:\n', res.stdout);

  ssh.dispose();
}

run().catch(console.error);
