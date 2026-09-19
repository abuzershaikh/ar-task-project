const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  
  const sql = "SELECT id, task_type, status, requirements FROM tasks WHERE id IN ('9fd1b667-9f6c-4e18-bb90-f21b0107980b', 'df50e363-aa85-47e3-8198-3b8143c5bbf6', '139c6126-920b-4984-9146-caac0b81ccb8', '150d2877-6a4f-4134-98a2-970fbd2168c6');";
  const res = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "${sql}"`);
  console.log(res.stdout);

  process.exit(0);
}

run().catch(console.error);
