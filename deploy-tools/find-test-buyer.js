const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
    const w = await ssh.execCommand('curl -s -H "x-user-email: admin@taskpost.com" -H "x-user-id: 102f44e4-a79a-4efd-88c8-b32927bd7ea7" -H "x-user-role: SUPER_ADMIN" http://127.0.0.1:3000/api/v1/admin/workers');
    const data = JSON.parse(w.stdout);
    console.log('Total workers returned:', data.workers ? data.workers.length : 0);
    
    console.log('\n--- Searching for "test" or "buyer" in workers API response: ---');
    data.workers.forEach(worker => {
      const match = (worker.name || '').toLowerCase().includes('buyer') || 
                    (worker.email || '').toLowerCase().includes('buyer') ||
                    (worker.name || '').toLowerCase().includes('test') ||
                    (worker.email || '').toLowerCase().includes('test');
      if (match) {
        console.log('FOUND MATCH IN API:', JSON.stringify(worker, null, 2));
      }
    });

    console.log('\n--- Checking MySQL directly for users with "buyer" or "test" in email or name: ---');
    const sql = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, email, role, full_name FROM users WHERE email LIKE \'%buyer%\' OR email LIKE \'%test%\' OR full_name LIKE \'%buyer%\' OR full_name LIKE \'%test%\';"');
    console.log(sql.stdout);

    console.log('\n--- Checking SQLite cache in Admin app (if any) or Flutter code: ---');
  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

run();
