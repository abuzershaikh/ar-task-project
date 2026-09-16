const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function main() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== USERS WITH METADATA / FCM TOKENS ===');
    const u = await ssh.execCommand('mysql -e "SELECT id, email, role, metadata FROM task_platform.users WHERE metadata IS NOT NULL;"');
    console.log(u.stdout);

    console.log('=== ADMIN USERS ===');
    const a = await ssh.execCommand('mysql -e "SELECT id, email, role, metadata FROM task_platform.users WHERE role IN (\'ADMIN\', \'SUPER_ADMIN\');"');
    console.log(a.stdout);

    console.log('=== NOTIFICATIONS TABLE SCHEMA & CONTENT ===');
    const descN = await ssh.execCommand('mysql -e "DESCRIBE task_platform.notifications;"');
    console.log(descN.stdout);

    const n = await ssh.execCommand('mysql -e "SELECT * FROM task_platform.notifications ORDER BY created_at DESC LIMIT 10;"');
    console.log(n.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

main();
