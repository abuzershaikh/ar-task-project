const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function main() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });
  await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "UPDATE tasks SET order_unit_id = JSON_UNQUOTE(JSON_EXTRACT(requirements, '$.orderUnitId')) WHERE (order_unit_id IS NULL OR order_unit_id = '') AND JSON_EXTRACT(requirements, '$.orderUnitId') IS NOT NULL;"`);
  await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "UPDATE task_assignments ta JOIN tasks t ON ta.task_id = t.id SET ta.order_unit_id = t.order_unit_id, ta.order_id = t.order_id WHERE (ta.order_unit_id IS NULL OR ta.order_unit_id = '') AND t.order_unit_id IS NOT NULL;"`);
  await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "UPDATE campaign_worker_participation cwp JOIN users u ON cwp.worker_id = u.id SET cwp.worker_id = LOWER(TRIM(u.email)) WHERE cwp.worker_id NOT LIKE '%@%';"`);
  await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "UPDATE task_assignments ta JOIN users u ON ta.worker_id = u.id SET ta.worker_id = LOWER(TRIM(u.email)) WHERE ta.worker_id NOT LIKE '%@%';"`);
  await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "UPDATE tasks t JOIN users u ON t.assigned_to = u.id SET t.assigned_to = LOWER(TRIM(u.email)) WHERE t.assigned_to IS NOT NULL AND t.assigned_to != '' AND t.assigned_to NOT LIKE '%@%';"`);
  const cwp = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "SELECT campaign_id, worker_id, status FROM campaign_worker_participation LIMIT 10;"`);
  console.log('Migrated CWP:', cwp.stdout);
  ssh.dispose();
}
main().catch(console.error);
