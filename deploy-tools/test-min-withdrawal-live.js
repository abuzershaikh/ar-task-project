const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function main() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 30000,
  });

  // 1. Login as admin
  const loginCmd = `curl -s -X POST http://localhost:3000/api/v1/auth/login -H "Content-Type: application/json" -d '{"email":"snapbizux@gmail.com","password":"80978097"}'`;
  const loginRes = await ssh.execCommand(loginCmd);
  const loginJson = JSON.parse(loginRes.stdout);
  const token = loginJson.token || loginJson.accessToken;
  console.log('Admin login success. Token obtained.');

  // 2. Test GET /admin/settings
  console.log('\n--- 1. Testing GET /admin/settings ---');
  const getSettingsCmd = `curl -s -H "Authorization: Bearer ${token}" http://localhost:3000/api/v1/admin/settings`;
  const getSettingsRes = await ssh.execCommand(getSettingsCmd);
  const parsedGet = JSON.parse(getSettingsRes.stdout);
  console.log('minWithdrawalAmount:', parsedGet.minWithdrawalAmount);
  console.log('minWithdrawalLimit:', parsedGet.minWithdrawalLimit);
  console.log('maintenanceMode:', parsedGet.maintenanceMode);
  console.log('platformMargin:', parsedGet.platformMargin);

  // 3. Test POST /admin/settings with minWithdrawalAmount: 150
  console.log('\n--- 2. Testing POST /admin/settings (updating to ₹100) ---');
  const postCmd = `curl -s -X POST http://localhost:3000/api/v1/admin/settings -H "Authorization: Bearer ${token}" -H "Content-Type: application/json" -d '{"minWithdrawalAmount":100,"maintenanceMode":false,"platformMargin":20}'`;
  const postRes = await ssh.execCommand(postCmd);
  console.log('POST Response:', postRes.stdout);

  // 4. Verify GET /admin/payouts/config
  console.log('\n--- 3. Testing GET /admin/payouts/config ---');
  const payoutCfgCmd = `curl -s -H "Authorization: Bearer ${token}" http://localhost:3000/api/v1/admin/payouts/config`;
  const payoutCfgRes = await ssh.execCommand(payoutCfgCmd);
  console.log('Payout Config Response:', payoutCfgRes.stdout);

  // 5. Verify MySQL DB system_settings row
  console.log('\n--- 4. Checking MySQL system_settings table row ---');
  const dbRes = await ssh.execCommand("mysql -u taskapp -ptaskapp_password task_platform -e 'SELECT * FROM system_settings WHERE `key` = \"minimum_withdrawal\";'");
  console.log(dbRes.stdout);

  // 6. Test Worker wallet response to see if Worker API returns 150
  console.log('\n--- 5. Checking Worker Wallet endpoint (simulated) ---');
  // Check any worker user from DB
  const workerUserRes = await ssh.execCommand("mysql -u taskapp -ptaskapp_password task_platform -e 'SELECT u.id, u.email FROM users u INNER JOIN workers w ON w.user_id = u.id LIMIT 1;'");
  console.log('Worker sample:', workerUserRes.stdout);

  ssh.dispose();
}

main().catch(console.error);
