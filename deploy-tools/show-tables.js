const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    const tables = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SHOW TABLES;"');
    console.log('=== ALL TABLES ===\n', tables.stdout);

    const users = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT * FROM users LIMIT 10;"');
    console.log('=== USERS ===\n', users.stdout);

    const workers = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT * FROM workers LIMIT 10;"');
    console.log('=== WORKERS ===\n', workers.stdout);

  } catch (e) {
    console.error(e);
  } finally {
    ssh.dispose();
  }
}

run();
