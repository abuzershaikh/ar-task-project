const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== SERVICE CATALOG (YOUTUBE) ===');
    const sc = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, code, name, category, buyer_unit_price, worker_reward, watch_time_options FROM service_catalog WHERE code LIKE '%YT%' OR code LIKE '%YOUTUBE%';"`);
    console.log(sc.stdout);

    console.log('=== RECENT YOUTUBE ORDERS ===');
    const orders = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, service_code, buyer_unit_price, reward_per_task, worker_reward_snapshot, total_amount, requirements FROM orders WHERE service_code LIKE '%YT%' OR service_code LIKE '%YOUTUBE%' ORDER BY created_at DESC LIMIT 5;"`);
    console.log(orders.stdout);

    console.log('=== TASKS FOR LATEST YT ORDER ===');
    const latestOrderIdRes = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -se "SELECT id FROM orders WHERE service_code LIKE '%YT%' OR service_code LIKE '%YOUTUBE%' ORDER BY created_at DESC LIMIT 1;"`);
    const latestOrderId = latestOrderIdRes.stdout.trim();
    if (latestOrderId) {
      console.log('Latest Order ID:', latestOrderId);
      const tasks = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, task_type, reward_amount, requirements, metadata FROM tasks WHERE order_id = '${latestOrderId}' LIMIT 2;"`);
      console.log(tasks.stdout);
    }
  } catch (e) {
    console.error('Error:', e);
  } finally {
    ssh.dispose();
  }
}

run();
