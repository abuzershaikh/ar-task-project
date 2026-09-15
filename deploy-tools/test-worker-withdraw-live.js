const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function main() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    const testScript = `
const http = require('http');
const jwt = require('/opt/task-engine/node_modules/jsonwebtoken');
require('/opt/task-engine/node_modules/dotenv').config({ path: '/opt/task-engine/.env' });

function request(method, path, data = null, token = null) {
  return new Promise((resolve, reject) => {
    const postData = data ? JSON.stringify(data) : '';
    const options = {
      hostname: '127.0.0.1',
      port: 3000,
      path: '/api/v1' + path,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { 'Authorization': 'Bearer ' + token } : {}),
        ...(data ? { 'Content-Length': Buffer.byteLength(postData) } : {}),
      },
    };

    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, data: JSON.parse(body) });
        } catch (_) {
          resolve({ status: res.statusCode, raw: body });
        }
      });
    });

    req.on('error', reject);
    if (postData) req.write(postData);
    req.end();
  });
}

async function run() {
  const secret = process.env.JWT_SECRET || 'super_secret_jwt_key_1234567890';
  
  // 1. Worker Auth Token
  const workerPayload = {
    sub: 'kQzd3bZD7pgA908xGE6NoGogetB3',
    email: 'sufieditz@gmail.com',
    role: 'WORKER',
  };
  const workerToken = jwt.sign(workerPayload, secret, { expiresIn: '1d' });

  // 2. Admin Auth Token
  const adminPayload = {
    sub: '102f44e4-a79a-4efd-88c8-b32927bd7ea7',
    email: 'admin@taskpost.com',
    role: 'SUPER_ADMIN',
  };
  const adminToken = jwt.sign(adminPayload, secret, { expiresIn: '1d' });

  console.log('--- 1. Testing Worker Balance Before Withdrawal ---');
  const walletBefore = await request('GET', '/worker/earnings/wallet', null, workerToken);
  console.log('Available Balance:', walletBefore.data?.wallet?.availableBalance);
  console.log('Reserved Balance:', walletBefore.data?.wallet?.reservedBalance);

  console.log('\\n--- 2. Worker Requesting Withdrawal of ₹100 ---');
  const withdrawRes = await request('POST', '/worker/earnings/withdraw', {
    amount: 100,
    paymentMethodId: '7400192134@ybl',
  }, workerToken);
  console.log('Withdraw Response Status:', withdrawRes.status);
  console.log('Withdraw Response Data:', JSON.stringify(withdrawRes.data, null, 2));

  const withdrawalId = withdrawRes.data?.withdrawalId;

  console.log('\\n--- 3. Querying Admin Pending Payouts Queue ---');
  const pendingRes = await request('GET', '/admin/payouts/pending', null, adminToken);
  console.log('Admin Pending Payouts Status:', pendingRes.status);
  console.log('Pending Count:', pendingRes.data?.count);
  console.log('Pending Withdrawals:', JSON.stringify(pendingRes.data?.withdrawals, null, 2));

  console.log('\\n--- 4. Worker Wallet Balance After Withdrawal ---');
  const walletAfter = await request('GET', '/worker/earnings/wallet', null, workerToken);
  console.log('Available Balance:', walletAfter.data?.wallet?.availableBalance);
  console.log('Reserved Balance:', walletAfter.data?.wallet?.reservedBalance);

  if (withdrawalId) {
    console.log('\\n--- 5. Admin Approves & Processes Withdrawal ---');
    const processRes = await request('POST', \`/admin/payouts/\${withdrawalId}/process\`, {
      transactionId: 'UPI-REF-' + Date.now(),
    }, adminToken);
    console.log('Process Response:', JSON.stringify(processRes.data, null, 2));

    console.log('\\n--- 6. Verify Pending Queue is Now Cleared ---');
    const pendingAfter = await request('GET', '/admin/payouts/pending', null, adminToken);
    console.log('Pending Count After Approval:', pendingAfter.data?.count);

    console.log('\\n--- 7. Worker Wallet Balance After Approval (Paid) ---');
    const walletFinal = await request('GET', '/worker/earnings/wallet', null, workerToken);
    console.log('Final Available Balance:', walletFinal.data?.wallet?.availableBalance);
    console.log('Final Reserved Balance:', walletFinal.data?.wallet?.reservedBalance);
  }
}

run().catch(console.error);
`;

    const remoteBase = '/opt/task-engine';
    await ssh.execCommand(`cat << 'EOF' > ${remoteBase}/test-withdraw-runner.js\n${testScript}\nEOF`);
    const res = await ssh.execCommand(`node test-withdraw-runner.js`, { cwd: remoteBase });
    console.log(res.stdout);
    if (res.stderr) console.error('STDERR:', res.stderr);

    await ssh.execCommand(`rm -f ${remoteBase}/test-withdraw-runner.js`);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

main();
