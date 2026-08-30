const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function checkBuyerWalletsMysql() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });

    console.log('=== Querying DB directly via mysql2 ===');
    const res = await ssh.execCommand(`node -e "
      const mysql = require('mysql2/promise');
      (async () => {
        const conn = await mysql.createConnection({
          host: '127.0.0.1',
          user: 'taskapp',
          password: 'taskapp_password',
          database: 'task_platform'
        });
        const [users] = await conn.query('SELECT id, email, role, full_name, created_at FROM users');
        console.log('All Users in DB:');
        console.table(users);
        const [wallets] = await conn.query('SELECT w.id, w.user_id, u.email, u.role, w.available_balance, w.reserved_balance FROM wallets w LEFT JOIN users u ON w.user_id = u.id');
        console.log('All Wallets in DB:');
        console.table(wallets);
        await conn.end();
      })();
    "`, { cwd: '/opt/task-engine' });

    console.log(res.stdout);
    if (res.stderr) console.error('STDERR:', res.stderr);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

checkBuyerWalletsMysql();
