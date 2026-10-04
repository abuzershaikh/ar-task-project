const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

(async () => {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== PM2 RECENT LOGS (API) ===');
    const logs = await ssh.execCommand('pm2 logs task-engine-api --lines 80 --nostream');
    console.log(logs.stdout);
    console.log(logs.stderr);

    console.log('=== FIND 9774f206-32c5-4e44-b2de-f4b59cfe81fb ===');
    const find1 = await ssh.execCommand("mysql -u taskapp -ptaskapp_password task_platform -e \"SELECT * FROM buyers WHERE id='9774f206-32c5-4e44-b2de-f4b59cfe81fb' OR user_id='9774f206-32c5-4e44-b2de-f4b59cfe81fb';\"");
    console.log('In buyers table:', find1.stdout);

    const find2 = await ssh.execCommand("mysql -u taskapp -ptaskapp_password task_platform -e \"SELECT * FROM users WHERE id='9774f206-32c5-4e44-b2de-f4b59cfe81fb';\"");
    console.log('In users table:', find2.stdout);

    const findOrders = await ssh.execCommand("mysql -u taskapp -ptaskapp_password task_platform -e \"SELECT distinct buyer_id FROM orders;\"");
    console.log('Distinct buyer_ids in orders:', findOrders.stdout);



    ssh.dispose();
  } catch (err) {
    console.error(err);
    ssh.dispose();
  }
})();
