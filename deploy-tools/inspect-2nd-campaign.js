const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function inspectCampaignsAndTasks() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== 1. Orders in Database ===');
    const ordersRes = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, buyer_id, service_id, status, quantity, total_price, created_at FROM orders ORDER BY created_at DESC LIMIT 10;"');
    console.log(ordersRes.stdout || '(No orders)');

    console.log('\n=== 2. Campaigns in Database ===');
    const campaignsRes = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, buyer_id, campaign_name, task_type, total_units, remaining_units, status, created_at FROM campaigns ORDER BY created_at DESC LIMIT 10;"');
    console.log(campaignsRes.stdout || '(No campaigns)');

    console.log('\n=== 3. Tasks in Database ===');
    const tasksRes = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, order_id, campaign_id, task_type, status, assigned_to, reward_amount, created_at FROM tasks ORDER BY created_at DESC LIMIT 25;"');
    console.log(tasksRes.stdout || '(No tasks)');

    console.log('\n=== 4. Workers & Participations ===');
    const workersRes = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, email, role, full_name FROM users WHERE role = \'WORKER\';"');
    console.log('Workers:');
    console.log(workersRes.stdout || '(No workers)');

    const partRes = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT * FROM campaign_worker_participations LIMIT 20;"');
    console.log('Participations:');
    console.log(partRes.stdout || '(No participations)');

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

inspectCampaignsAndTasks();
