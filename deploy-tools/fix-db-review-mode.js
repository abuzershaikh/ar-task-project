const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function fixDb() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  console.log('=== FIXING REVIEW_MODE IN MYSQL ===');
  await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "UPDATE service_catalog SET review_mode = LOWER(review_mode) WHERE review_mode IS NOT NULL;"`);
  await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "UPDATE orders SET review_mode = LOWER(review_mode) WHERE review_mode IS NOT NULL;"`);
  
  // Also fix the failed submission for df50e363-aa85-47e3-8198-3b8143c5bbf6
  await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "UPDATE task_submissions SET reviewed_by = 'PZxQCgtXW0hPflGEXM98zLaQNKQ2', review_status = 'pending' WHERE task_id = 'df50e363-aa85-47e3-8198-3b8143c5bbf6';"`);

  console.log('=== VERIFY SERVICE CATALOG ===');
  const r1 = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "SELECT code, review_mode FROM service_catalog;"`);
  console.log(r1.stdout);

  console.log('=== VERIFY ORDERS ===');
  const r2 = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "SELECT DISTINCT review_mode FROM orders;"`);
  console.log(r2.stdout);

  console.log('=== VERIFY SUBMISSION ===');
  const r3 = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, task_id, worker_id, status, review_status, reviewed_by FROM task_submissions WHERE task_id = 'df50e363-aa85-47e3-8198-3b8143c5bbf6' \\G"`);
  console.log(r3.stdout);

  ssh.dispose();
}

fixDb();
