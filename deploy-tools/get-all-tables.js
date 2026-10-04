const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    const res = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SHOW TABLES;"');
    console.log('=== MYSQL TABLES IN task_platform ===\n');
    console.log(res.stdout);

    const version = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT VERSION();"');
    console.log('=== DATABASE VERSION ===\n', version.stdout);

  } catch (e) {
    console.error(e);
  } finally {
    ssh.dispose();
  }
}

run();
