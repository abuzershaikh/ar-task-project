const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function truncateDemoTables() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('--- Truncating Demo Task & Order Tables ---');

    await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "
      SET FOREIGN_KEY_CHECKS = 0;
      TRUNCATE TABLE submissions;
      TRUNCATE TABLE order_units;
      TRUNCATE TABLE tasks;
      TRUNCATE TABLE task_generation_jobs;
      TRUNCATE TABLE orders;
      TRUNCATE TABLE campaign_worker_participations;
      DELETE FROM users WHERE email LIKE '%@test.com' OR email LIKE '%worker_app_user%';
      SET FOREIGN_KEY_CHECKS = 1;
    "`);

    console.log('✅ All demo tasks, demo orders, and demo users wiped clean!');

    const tasks = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT count(*) as total_tasks FROM tasks;"');
    console.log('Tasks in DB:', tasks.stdout.trim());

    const orders = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT count(*) as total_orders FROM orders;"');
    console.log('Orders in DB:', orders.stdout.trim());

    const apiTest = await ssh.execCommand('curl -s -H "x-user-email: snapbizux@gmail.com" -H "x-user-id: 15QuKnQDcwS5NLacLIQ8V8CElnA2" -H "x-user-role: WORKER" http://127.0.0.1:3000/api/v1/worker/tasks/available');
    console.log('\nWorker Available Tasks API (Should be empty array []):');
    console.log(apiTest.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

truncateDemoTables();
