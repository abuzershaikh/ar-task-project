const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function check() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
    
    console.log('--- ADMIN WORKERS ---');
    const w = await ssh.execCommand('curl -s -H "x-user-email: admin@taskpost.com" -H "x-user-id: 102f44e4-a79a-4efd-88c8-b32927bd7ea7" -H "x-user-role: SUPER_ADMIN" http://127.0.0.1:3000/api/v1/admin/workers');
    console.log(w.stdout);

    console.log('\n--- ADMIN BUYERS ---');
    const b = await ssh.execCommand('curl -s -H "x-user-email: admin@taskpost.com" -H "x-user-id: 102f44e4-a79a-4efd-88c8-b32927bd7ea7" -H "x-user-role: SUPER_ADMIN" http://127.0.0.1:3000/api/v1/admin/buyers');
    console.log(b.stdout);

    console.log('\n--- MYSQL USERS ---');
    const u = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, email, role, full_name, created_at FROM users;"');
    console.log(u.stdout);

    console.log('\n--- MYSQL WORKERS ---');
    const wSql = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, user_id, status, created_at FROM workers;"');
    console.log(wSql.stdout);

    console.log('\n--- RECENT PM2 LOGS (AUTH/SYNC) ---');
    const logs = await ssh.execCommand('tail -n 40 /root/.pm2/logs/task-engine-api-out.log');
    console.log(logs.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

check();
