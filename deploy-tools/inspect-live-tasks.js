const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function inspectTasks() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== Tasks in Database ===');
    const res = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, order_id, campaign_id, task_type, reward_amount, status, assigned_to FROM tasks LIMIT 40;"');
    console.log(res.stdout || '(No tasks found)');

    console.log('\n=== Orders in Database ===');
    const orders = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, buyer_id, service_code, status, total_amount, created_at FROM orders LIMIT 20;"');
    console.log(orders.stdout || '(No orders found)');

    console.log('\n=== Available Tasks via API test ===');
    const apiRes = await ssh.execCommand('curl -s -H "x-user-email: snapbizux@gmail.com" -H "x-user-id: 15QuKnQDcwS5NLacLIQ8V8CElnA2" -H "x-user-role: WORKER" http://127.0.0.1:3000/api/v1/worker/tasks/available');
    console.log(apiRes.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

inspectTasks();
