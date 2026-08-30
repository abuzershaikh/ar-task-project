const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function cleanDemoData() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('--- Cleaning Demo / Test Orders & Tasks ---');

    // 1. Delete submissions, order_units, tasks, task_generation_jobs, orders created by test buyers (@test.com or TEST_)
    await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "
      SET FOREIGN_KEY_CHECKS = 0;
      DELETE FROM submissions WHERE task_id IN (SELECT id FROM tasks WHERE order_id LIKE 'TEST_%' OR order_id = 'a5a43e8e-729e-47dc-8c84-efe1f535a110');
      DELETE FROM order_units WHERE order_id LIKE 'TEST_%' OR order_id = 'a5a43e8e-729e-47dc-8c84-efe1f535a110';
      DELETE FROM tasks WHERE order_id LIKE 'TEST_%' OR order_id = 'a5a43e8e-729e-47dc-8c84-efe1f535a110';
      DELETE FROM task_generation_jobs WHERE order_id LIKE 'TEST_%' OR order_id = 'a5a43e8e-729e-47dc-8c84-efe1f535a110';
      DELETE FROM orders WHERE id LIKE 'TEST_%' OR id = 'a5a43e8e-729e-47dc-8c84-efe1f535a110' OR buyer_id IN (SELECT id FROM users WHERE email LIKE '%@test.com');
      DELETE FROM users WHERE email LIKE '%@test.com';
      SET FOREIGN_KEY_CHECKS = 1;
    "`);

    console.log('✅ Demo tasks and test buyer data deleted successfully!');

    // 2. Check remaining tasks
    const remainingTasks = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, order_id, task_type, reward_amount, status FROM tasks;"');
    console.log('\nRemaining Tasks in Database:');
    console.log(remainingTasks.stdout || '(0 tasks - clean state)');

    // 3. Check remaining orders
    const remainingOrders = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT o.id, u.email as buyer_email, o.service_code, o.status FROM orders o LEFT JOIN users u ON o.buyer_id = u.id;"');
    console.log('\nRemaining Orders in Database:');
    console.log(remainingOrders.stdout || '(0 orders - clean state)');

    // 4. Test API response for Worker
    const apiTest = await ssh.execCommand('curl -s -H "x-user-email: snapbizux@gmail.com" -H "x-user-id: 15QuKnQDcwS5NLacLIQ8V8CElnA2" -H "x-user-role: WORKER" http://127.0.0.1:3000/api/v1/worker/tasks/available');
    console.log('\nWorker Available Tasks API output:');
    console.log(apiTest.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

cleanDemoData();
