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
           JSON_UNQUOTE(JSON_EXTRACT(requirements, '$.targetUrl')) as url,
           JSON_UNQUOTE(JSON_EXTRACT(requirements, '$.packageId')) as pkg
    FROM tasks
    WHERE requirements LIKE '%autopaycancel.autopaymanager%'
    LIMIT 20;
  `;
  
  await ssh.execCommand(`cat << 'EOF' > /tmp/check_autopay.sql\n${sql}\nEOF`);
  const res = await ssh.execCommand('mysql task_platform < /tmp/check_autopay.sql');
  console.log('Autopay tasks:\n', res.stdout);

  const sql2 = `
    SELECT id, order_id, status, assigned_to, 
           SUBSTRING(JSON_UNQUOTE(JSON_EXTRACT(requirements, '$.targetUrl')), 1, 80) as url,
           JSON_UNQUOTE(JSON_EXTRACT(requirements, '$.businessName')) as bName
    FROM tasks
    WHERE requirements LIKE '%HOTEL BNB PALACE%'
    LIMIT 20;
  `;
  
  await ssh.execCommand(`cat << 'EOF' > /tmp/check_bnb.sql\n${sql2}\nEOF`);
  const res2 = await ssh.execCommand('mysql task_platform < /tmp/check_bnb.sql');
  console.log('BNB tasks:\n', res2.stdout);

  ssh.dispose();
}

run().catch(console.error);
