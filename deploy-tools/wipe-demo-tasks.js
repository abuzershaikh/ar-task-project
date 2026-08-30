const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function clean() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
    
    const cmds = [
      'mysql -u taskapp -ptaskapp_password task_platform -e "SET FOREIGN_KEY_CHECKS = 0; DELETE FROM submissions; SET FOREIGN_KEY_CHECKS = 1;"',
      'mysql -u taskapp -ptaskapp_password task_platform -e "SET FOREIGN_KEY_CHECKS = 0; DELETE FROM order_units; SET FOREIGN_KEY_CHECKS = 1;"',
      'mysql -u taskapp -ptaskapp_password task_platform -e "SET FOREIGN_KEY_CHECKS = 0; DELETE FROM tasks; SET FOREIGN_KEY_CHECKS = 1;"',
      'mysql -u taskapp -ptaskapp_password task_platform -e "SET FOREIGN_KEY_CHECKS = 0; DELETE FROM task_generation_jobs; SET FOREIGN_KEY_CHECKS = 1;"',
      'mysql -u taskapp -ptaskapp_password task_platform -e "SET FOREIGN_KEY_CHECKS = 0; DELETE FROM orders; SET FOREIGN_KEY_CHECKS = 1;"',
      'mysql -u taskapp -ptaskapp_password task_platform -e "SET FOREIGN_KEY_CHECKS = 0; DELETE FROM campaign_worker_participations; SET FOREIGN_KEY_CHECKS = 1;"',
      'mysql -u taskapp -ptaskapp_password task_platform -e "SET FOREIGN_KEY_CHECKS = 0; DELETE FROM users WHERE email LIKE \'%@test.com\'; SET FOREIGN_KEY_CHECKS = 1;"',
    ];

    for (const cmd of cmds) {
      const res = await ssh.execCommand(cmd);
      if (res.stderr) console.error(res.stderr);
    }

    console.log('--- Verification after Wipe ---');
    const tasks = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT count(*) as total_tasks FROM tasks;"');
    console.log(tasks.stdout.trim());

    const orders = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT count(*) as total_orders FROM orders;"');
    console.log(orders.stdout.trim());

    const apiTest = await ssh.execCommand('curl -s -H "x-user-email: snapbizux@gmail.com" -H "x-user-id: 15QuKnQDcwS5NLacLIQ8V8CElnA2" -H "x-user-role: WORKER" http://127.0.0.1:3000/api/v1/worker/tasks/available');
    console.log('\nWorker Available Tasks API response:', apiTest.stdout);

  } catch (e) {
    console.error(e);
  } finally {
    ssh.dispose();
  }
}

clean();
