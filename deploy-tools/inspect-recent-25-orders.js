const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  
  const sql = `
    SELECT id, title, service_code, status, total_tasks_required, created_at,
           JSON_UNQUOTE(JSON_EXTRACT(requirements, '$.targetUrl')) as target_url,
           JSON_UNQUOTE(JSON_EXTRACT(requirements, '$.businessName')) as business_name,
           JSON_UNQUOTE(JSON_EXTRACT(requirements, '$.appName')) as app_name
    FROM orders
    ORDER BY created_at DESC
    LIMIT 25;
  `;
  const res = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "${sql}"`);
  console.log('RECENT 25 ORDERS:\n', res.stdout);

  ssh.dispose();
}

run().catch(console.error);
