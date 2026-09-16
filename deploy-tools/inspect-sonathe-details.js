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

    const walletId = '66111842-96d5-462a-9122-83a121c1033d';
    const userId = 'MYDovhuR8zcbLlvazaAG8qdWLXr1';

    console.log('=== 1. WALLET TRANSACTIONS FOR THIS WALLET ===');
    const wtRes = await ssh.execCommand(`mysql -e 'SELECT * FROM task_platform.wallet_transactions WHERE wallet_id = "${walletId}" ORDER BY created_at DESC;'`);
    console.log(wtRes.stdout);

    console.log('=== 2. ANY WALLET TRANSACTIONS WITH 5.50 ACROSS ENTIRE DB ===');
    const wt5 = await ssh.execCommand("mysql -e 'SELECT * FROM task_platform.wallet_transactions WHERE amount = 5.50 OR balance_after = 5.50 OR description LIKE \"%5.5%\" ORDER BY created_at DESC;'");
    console.log(wt5.stdout);

    console.log('=== 3. ORDERS BY THIS USER ===');
    const oRes = await ssh.execCommand(`mysql -e 'SELECT id, title, task_type, status, total_amount, total_budget, unit_price, total_tasks_required, created_at FROM task_platform.orders WHERE buyer_id = "${userId}" ORDER BY created_at DESC;'`);
    console.log(oRes.stdout);

    console.log('=== 4. PAYMENT TRANSACTIONS FOR THIS USER ===');
    const ptDesc = await ssh.execCommand("mysql -e 'DESCRIBE task_platform.payment_transactions;'");
    console.log('PT schema:\n', ptDesc.stdout);
    const ptRes = await ssh.execCommand(`mysql -e 'SELECT * FROM task_platform.payment_transactions WHERE user_id = "${userId}" OR buyer_id = "${userId}";'`);
    console.log('PT rows:\n', ptRes.stdout);

    console.log('=== 5. ANY RECORD WITH 5.50 IN ORDERS ===');
    const ord5 = await ssh.execCommand("mysql -e 'SELECT id, buyer_id, title, status, total_amount, unit_price, reward_per_task, created_at FROM task_platform.orders WHERE total_amount = 5.50 OR unit_price = 5.50 OR buyer_unit_price = 5.50;'");
    console.log(ord5.stdout);

    console.log('=== 6. ANY RECORD WITH 5.50 IN ORDER_UNITS ===');
    const ou5 = await ssh.execCommand("mysql -e 'SELECT * FROM task_platform.order_units WHERE amount = 5.50 OR price = 5.50 LIMIT 10;'");
    console.log(ou5.stdout);

    console.log('=== 7. AUDIT LOGS FOR THIS USER ===');
    const aRes = await ssh.execCommand(`mysql -e 'SELECT * FROM task_platform.audit_logs WHERE user_id = "${userId}" OR target_id = "${userId}" ORDER BY created_at DESC LIMIT 10;'`);
    console.log(aRes.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

run();
