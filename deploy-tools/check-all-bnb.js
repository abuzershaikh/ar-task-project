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
    SELECT id, order_id, status, assigned_to, 
           SUBSTRING(JSON_UNQUOTE(JSON_EXTRACT(requirements, '$.targetUrl')), 1, 60) as url,
           JSON_UNQUOTE(JSON_EXTRACT(requirements, '$.businessName')) as bName
    FROM tasks
    WHERE (requirements LIKE '%BNB PALACE%' OR requirements LIKE '%bnb%palace%')
      AND assigned_to IS NOT NULL;
  `;
  
  await ssh.execCommand(`cat << 'EOF' > /tmp/check_all_bnb.sql\n${sql}\nEOF`);
  const res = await ssh.execCommand('mysql task_platform < /tmp/check_all_bnb.sql');
  console.log('All BNB tasks:\n', res.stdout);

  ssh.dispose();
}

run().catch(console.error);
