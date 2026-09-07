const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  const sql = "SELECT id, title, buyer_id, created_at FROM orders ORDER BY created_at DESC LIMIT 10";
  const res = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "${sql}"`);
  console.log('Recent orders:\n', res.stdout);

  console.log('\n--- Recent transactions ---');
  const sql2 = "SELECT t.id, t.wallet_id, w.user_id, u.email, t.amount, t.type, t.description, t.created_at FROM wallet_transactions t LEFT JOIN wallets w ON t.wallet_id = w.id LEFT JOIN users u ON w.user_id = u.id ORDER BY t.created_at DESC LIMIT 10";
  const res2 = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "${sql2}"`);
  console.log(res2.stdout);

  ssh.dispose();
}
run();
