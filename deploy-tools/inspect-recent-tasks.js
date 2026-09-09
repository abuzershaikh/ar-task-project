const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function main() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });
  const res = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, order_id, task_type, JSON_UNQUOTE(JSON_EXTRACT(requirements, '$.appName')) as appName, JSON_UNQUOTE(JSON_EXTRACT(requirements, '$.appIcon')) as appIcon, JSON_UNQUOTE(JSON_EXTRACT(requirements, '$.targetUrl')) as targetUrl, created_at FROM tasks ORDER BY created_at DESC LIMIT 15;"`);
  console.log(res.stdout);
  ssh.dispose();
}
main().catch(console.error);
