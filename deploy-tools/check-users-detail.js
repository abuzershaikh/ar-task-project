const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function main() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
    
    console.log('--- USERS TABLE DESCRIBE ---');
    const desc = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "DESCRIBE users;"');
    console.log(desc.stdout);

    console.log('--- ALL USERS (id, email, role, phone) ---');
    const users = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, email, role, phone FROM users;"');
    console.log(users.stdout);

    console.log('--- ALL WORKERS TABLE (id, userId, status) ---');
    const workers = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT * FROM workers LIMIT 5;"');
    console.log(workers.stdout);

    console.log('--- WALLETS TABLE (userId, balance, role) ---');
    const wallets = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "DESCRIBE wallets; SELECT * FROM wallets LIMIT 5;"');
    console.log(wallets.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

main();
