const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  
  // Check if sonathe has participated or has tasks in those campaigns
  const sql1 = "SELECT id, campaign_id, order_id, task_type, status, assigned_to FROM tasks WHERE assigned_to LIKE '%sonathe%' AND (campaign_id IN ('781a2e7d-5253-493e-a2fc-b5642c08bcf9', 'ee55f372-ec25-4028-ad2c-e46dc1775691') OR requirements LIKE '%growyourwealth%' OR requirements LIKE '%contactsaver%');";
  const res1 = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "${sql1}"`);
  console.log('Sonathe matching tasks:\n', res1.stdout);

  // Check submissions
  const sql2 = "SELECT id, task_id, worker_id, status FROM task_submissions WHERE worker_id LIKE '%sonathe%' OR worker_id = 'MYDovhuR8zcbLlvazaAG8qdWLXr1';";
  const res2 = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "${sql2}"`);
  console.log('Sonathe submissions:\n', res2.stdout);

  // Check what tasks for 781a2e7d and ee55f372 have status 'active' and assigned_to IS NULL
  const sql3 = "SELECT id, campaign_id, order_id, status, assigned_to FROM tasks WHERE order_id IN ('781a2e7d-5253-493e-a2fc-b5642c08bcf9', 'ee55f372-ec25-4028-ad2c-e46dc1775691') AND status = 'active' AND assigned_to IS NULL;";
  const res3 = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "${sql3}"`);
  console.log('Unassigned active tasks for 781a2e7d and ee55f372:\n', res3.stdout);

  process.exit(0);
}

run().catch(console.error);
