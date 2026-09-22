const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

(async () => {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('Testing Admin Login with snapbizux@gmail.com / 80978097...');
    const loginCmd = `curl -s -X POST http://localhost:3000/api/v1/auth/login -H "Content-Type: application/json" -d '{"email":"snapbizux@gmail.com","password":"80978097"}'`;
    const loginRes = await ssh.execCommand(loginCmd);
    const data = JSON.parse(loginRes.stdout);
    const token = data.data?.accessToken || data.data?.token || data.token;
    console.log('Token extracted:', token ? 'YES' : 'NO');

    console.log('\n--- Testing GET /api/v1/admin/analytics/revenue ---');
    const rev = await ssh.execCommand(`curl -s -H "Authorization: Bearer ${token}" http://localhost:3000/api/v1/admin/analytics/revenue`);
    const revJson = JSON.parse(rev.stdout);
    console.log({
      success: revJson.success,
      grossPlatformVolume: revJson.grossPlatformVolume,
      platformNetMargin: revJson.platformNetMargin,
      projectedMargin: revJson.projectedMargin,
      totalBuyerDeposits: revJson.totalBuyerDeposits,
      totalWorkerPayouts: revJson.totalWorkerPayouts,
      walletPoolBalance: revJson.walletPoolBalance,
      ledgerCount: revJson.ledger?.length,
    });

    console.log('\n--- Testing GET /api/v1/admin/analytics/ledger ---');
    const led = await ssh.execCommand(`curl -s -w "\nHTTP_STATUS: %{http_code}" -H "Authorization: Bearer ${token}" http://localhost:3000/api/v1/admin/analytics/ledger`);
    console.log(led.stdout);

    console.log('=== DESCRIBE ORDERS ===');
    const dord = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "DESCRIBE orders;"');
    console.log(dord.stdout);

    ssh.dispose();
  } catch (err) {
    console.error(err);
    ssh.dispose();
  }
})();
