const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
      readyTimeout: 60000,
    });

    console.log('--- USER RECORD ---');
    const uRes = await ssh.execCommand("mysql -e 'SELECT id, email, role, status, created_at, updated_at FROM task_platform.users WHERE email LIKE \"%sonathe333%\";'");
    console.log(uRes.stdout);

    console.log('--- WALLETS RECORD ---');
    const wRes = await ssh.execCommand("mysql -e 'SELECT w.* FROM task_platform.wallets w JOIN task_platform.users u ON w.user_id = u.id WHERE u.email LIKE \"%sonathe333%\";'");
    console.log(wRes.stdout);

    console.log('--- WALLET TRANSACTIONS ---');
    const wtRes = await ssh.execCommand("mysql -e 'SELECT wt.* FROM task_platform.wallet_transactions wt JOIN task_platform.users u ON wt.user_id = u.id WHERE u.email LIKE \"%sonathe333%\" ORDER BY wt.created_at DESC;'");
    console.log(wtRes.stdout);

    console.log('--- GENERAL TRANSACTIONS ---');
    const tRes = await ssh.execCommand("mysql -e 'SELECT t.* FROM task_platform.transactions t JOIN task_platform.users u ON t.user_id = u.id WHERE u.email LIKE \"%sonathe333%\" ORDER BY t.created_at DESC;'");
    console.log(tRes.stdout);

    console.log('--- TASK SUBMISSIONS / REWARDS (IF WORKER) ---');
    const sRes = await ssh.execCommand("mysql -e 'SELECT ts.id, ts.task_id, ts.status, ts.reward, ts.created_at, ts.reviewed_at, t.title FROM task_platform.task_submissions ts JOIN task_platform.users u ON ts.worker_id = u.id LEFT JOIN task_platform.tasks t ON ts.task_id = t.id WHERE u.email LIKE \"%sonathe333%\" ORDER BY ts.created_at DESC;'");
    console.log(sRes.stdout);

    console.log('--- ORDERS (IF BUYER) ---');
    const oRes = await ssh.execCommand("mysql -e 'SELECT o.id, o.service_id, o.status, o.total_amount, o.created_at FROM task_platform.orders o JOIN task_platform.users u ON o.buyer_id = u.id WHERE u.email LIKE \"%sonathe333%\" ORDER BY o.created_at DESC;'");
    console.log(oRes.stdout);

  } catch (err) {
    console.error('Error:', err);
  } finally {
    ssh.dispose();
  }
}

run();
