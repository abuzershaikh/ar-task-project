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
    SELECT 
      JSON_UNQUOTE(JSON_EXTRACT(requirements, '$.targetUrl')) as url,
      JSON_UNQUOTE(JSON_EXTRACT(requirements, '$.packageId')) as pkg,
      JSON_UNQUOTE(JSON_EXTRACT(requirements, '$.businessName')) as bName,
      COUNT(*) as order_count
    FROM orders
    WHERE task_type LIKE '%GOOGLE%' OR task_type LIKE '%PLAY%' OR task_type LIKE '%GMB%'
    GROUP BY url, pkg, bName
    HAVING order_count > 1;
  `;
  
  await ssh.execCommand(`cat << 'EOF' > /tmp/check_repeat_campaigns.sql\n${sql}\nEOF`);
  const res = await ssh.execCommand('mysql task_platform < /tmp/check_repeat_campaigns.sql');
  console.log('Repeat campaigns:\n', res.stdout);

  ssh.dispose();
}

run().catch(console.error);
