const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });

  console.log('=== CHECKING ALL GOOGLE_BUSINESS TASKS IN DB ===');
  const res = await ssh.execCommand(
    `mysql -u taskapp -ptaskapp_password task_platform -e "
      SELECT t.id, t.order_id, t.task_type, t.status as task_status, t.assigned_to, o.status as order_status, o.total_tasks_required, t.created_at
      FROM tasks t
      LEFT JOIN orders o ON t.order_id = o.id
      WHERE t.task_type LIKE '%GOOGLE%' OR t.task_type LIKE '%MAP%'
      ORDER BY t.created_at DESC LIMIT 30;
    "`
  );
  console.log(res.stdout);

  console.log('\n=== STATUS SUMMARY OF GOOGLE TASKS ===');
  const resSummary = await ssh.execCommand(
    `mysql -u taskapp -ptaskapp_password task_platform -e "
      SELECT t.status as task_status, o.status as order_status, COUNT(*) as count
      FROM tasks t
      LEFT JOIN orders o ON t.order_id = o.id
      WHERE t.task_type LIKE '%GOOGLE%' OR t.task_type LIKE '%MAP%'
      GROUP BY t.status, o.status;
    "`
  );
  console.log(resSummary.stdout);

  ssh.dispose();
}

run().catch(console.error);
