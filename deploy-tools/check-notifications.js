const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  console.log('=== ALL USERS (email, role, full_name, id) ===');
  const u = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, email, full_name, role FROM users;"');
  console.log(u.stdout);

  console.log('=== ALL NOTIFICATIONS SENT TODAY (or recent 20) ===');
  const n = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, user_id, type, title, message, status, created_at FROM notifications ORDER BY created_at DESC LIMIT 20;"');
  console.log(n.stdout);

  console.log('=== IN-APP NOTIFICATIONS (if any table) ===');
  const inApp = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT * FROM notifications WHERE message LIKE \'%Groww%\' OR title LIKE \'%Groww%\' OR metadata LIKE \'%groww%\' OR metadata LIKE \'%08bebc9c%\';"');
  console.log(inApp.stdout);

  ssh.dispose();
}

run();
