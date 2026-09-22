const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function checkAll() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== SHOW DATABASES ===');
    const dbs = await ssh.execCommand('mysql -u taskapp -ptaskapp_password -e "SHOW DATABASES;"');
    console.log(dbs.stdout);

    console.log('=== USERS IN task_platform ===');
    const u = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, email, full_name, role, status FROM users;"');
    console.log(u.stdout);

    console.log('=== WORKERS IN task_platform ===');
    const w = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT * FROM workers;"');
    console.log(w.stdout || '(Empty)\n');

    console.log('=== ORDERS IN task_platform ===');
    const o = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT * FROM orders;"');
    console.log(o.stdout || '(Empty)\n');

  } catch (e) {
    console.error(e);
  } finally {
    ssh.dispose();
  }
}

checkAll();
