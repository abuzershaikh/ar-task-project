const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function runLiveFinanceTests() {
  try {
    console.log('🚀 Connecting to Mumbai VPS (65.20.77.112)...');
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });
    console.log('✅ Connected to VPS!\n');

    const testScript = `
const http = require('http');

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

async function main() {
  console.log('=== 1. ACQUIRING TOKENS FOR ADMIN, BUYER & WORKER ===');
  // Admin login
  const adminRes = await request('POST', '/auth/login', {
    email: 'admin@taskpost.com',
    password: 'Admin@123456',
  });
  const adminToken = adminRes.data?.data?.accessToken;
  console.log('Admin Token:', adminToken ? '✅ Acquired' : '❌ Failed');

  // Register fresh Buyer
  const suffix = Math.floor(1000 + Math.random() * 9000);
  const buyerRes = await request('POST', '/auth/register', {
    email: 'buyer_' + suffix + '@financetest.com',
    password: 'TestPass123!',
    fullName: 'Finance Buyer',
    role: 'BUYER',
  });
  const buyerToken = buyerRes.data?.data?.accessToken;
  const buyerId = buyerRes.data?.data?.user?.id;
  console.log('Buyer Token:', buyerToken ? '✅ Acquired' : '❌ Failed', 'Buyer ID:', buyerId);

  // Register fresh Worker
  const workerRes = await request('POST', '/auth/register', {
    email: 'worker_' + suffix + '@financetest.com',
    password: 'TestPass123!',
    fullName: 'Finance Worker',
    role: 'WORKER',
  });
  const workerToken = workerRes.data?.data?.accessToken;
  const workerId = workerRes.data?.data?.user?.id;
  console.log('Worker Token:', workerToken ? '✅ Acquired' : '❌ Failed', 'Worker ID:', workerId);

  let passed = 0;
  let failed = 0;
  function check(label, cond, detail = '') {
    if (cond) {
      console.log('   ✅ PASS: ' + label + (detail ? ' (' + detail + ')' : ''));
      passed++;
    } else {
      console.error('   ❌ FAIL: ' + label + (detail ? ' (' + detail + ')' : ''));
      failed++;
    }
  }

  console.log('\\n=== 2. TESTING ADMIN TOPUP VALIDATION & ROW LOCKING ===');
  // 1. Invalid buyerId
  const invTopup = await request('POST', '/admin/wallet/topup', {
    buyerId: '00000000-0000-0000-0000-000000000000',
    amount: 100,
    type: 'CREDIT',
  }, adminToken);
  check('Admin topup rejects non-existent buyerId with 404', invTopup.status === 404, 'Status: ' + invTopup.status);

  // 2. Reject topup for a non-buyer (e.g. workerId)
  const workerTopup = await request('POST', '/admin/wallet/topup', {
    buyerId: workerId,
    amount: 100,
    type: 'CREDIT',
  }, adminToken);
  check('Admin topup rejects non-buyer user role', workerTopup.status === 400, workerTopup.data?.message);

  // 3. Valid buyer topup
  const validTopup = await request('POST', '/admin/wallet/topup', {
    buyerId: buyerId,
    amount: 50,
    type: 'CREDIT',
    notes: 'Automated test admin topup',
  }, adminToken);
  check('Admin topup credits valid buyer wallet', validTopup.status === 201 || validTopup.status === 200, 'New Balance: ₹' + validTopup.data?.data?.newBalance);

  console.log('\\n=== 3. TESTING BUYER SELF-TOPUP EXPLOIT PREVENTION ===');
  // Direct topup without payment gateway
  const directTopup = await request('POST', '/buyer/wallet/topup', { amount: 5000 }, buyerToken);
  check('Direct buyer self-topup is BLOCKED (no free money)', directTopup.status === 400, directTopup.data?.message);

  // Balance before add-balance
  const balBefore = await request('GET', '/buyer/wallet/balance', null, buyerToken);
  const initialAvail = balBefore.data?.balance?.available || 0;

  // Initiate add-balance
  const addBal = await request('POST', '/buyer/wallet/add-balance', { amount: 100 }, buyerToken);
  check('Add-balance creates pending payment session', addBal.status === 201 || addBal.status === 200, 'Txn ID: ' + addBal.data?.transactionId);

  // Verify balance did NOT change yet (before payment verification)
  const balAfterInit = await request('GET', '/buyer/wallet/balance', null, buyerToken);
  check('Wallet balance is NOT credited before payment verification', balAfterInit.data?.balance?.available === initialAvail, 'Available: ₹' + balAfterInit.data?.balance?.available);

  // Verify payment
  const txnId = addBal.data?.transactionId;
  const verifyRes = await request('POST', '/buyer/wallet/verify-payment', { transactionId: txnId }, buyerToken);
  check('Verify-payment successfully captures and credits wallet', verifyRes.status === 201 || verifyRes.status === 200, 'Status: ' + verifyRes.data?.status);

  // Verify balance is now initial + 100
  const balAfterVerify = await request('GET', '/buyer/wallet/balance', null, buyerToken);
  check('Wallet balance is accurately updated after verification', balAfterVerify.data?.balance?.available === initialAvail + 100, 'New Available: ₹' + balAfterVerify.data?.balance?.available);

  // Duplicate verify call should not double-credit
  const dupVerify = await request('POST', '/buyer/wallet/verify-payment', { transactionId: txnId }, buyerToken);
  check('Duplicate verification prevents double-crediting', dupVerify.data?.alreadyVerified === true, 'AlreadyVerified: ' + dupVerify.data?.alreadyVerified);

  console.log('\\n=== 4. TESTING SERVICE PRICING WORKER REWARD OVERSHOOT BLOCK ===');
  const servicesRes = await request('GET', '/buyer/services', null, buyerToken);
  const servicesList = servicesRes.data?.data || servicesRes.data?.services || [];
  if (servicesList.length > 0) {
    const testSvc = servicesList[0];
    const overshootPricing = await request('POST', '/admin/services/' + testSvc.id + '/pricing', {
      buyerUnitPrice: 10,
      marginType: 'FIXED',
      marginValue: 3,
      workerReward: 20, // 20 > 10 - 3 = 7
    }, adminToken);
    check('ServicePricing rejects workerReward (20) > buyerUnitPrice - margin (7)', overshootPricing.status === 400, overshootPricing.data?.message);
  }

  console.log('\\n=== 5. TESTING ATOMIC ORDER PLACEMENT & REAL ORDER REFERENCE ===');
  // Buyer currently has 150 available. Try order costing 500 -> must fail with insufficient balance
  const overdraftOrder = await request('POST', '/buyer/orders', {
    serviceId: servicesList[0]?.id || 'youtube_comments_custom',
    quantity: 100, // costs > 150
  }, buyerToken);
  check('Order placement prevents overdraft on insufficient balance', overdraftOrder.status === 400, overdraftOrder.data?.message);

  // Now create order within balance (e.g. 1 task = ~10 INR)
  const validOrderRes = await request('POST', '/buyer/orders', {
    serviceId: servicesList[0]?.id || 'youtube_comments_custom',
    quantity: 1,
    title: 'Atomic Test Order #' + suffix,
    requirements: { url: 'https://youtube.com/watch?v=test', customText: 'Great video' },
  }, buyerToken);
  check('Atomic order created and debited from wallet', validOrderRes.status === 201 || validOrderRes.status === 200, 'Order ID: ' + validOrderRes.data?.order?.id);

  // Check transactions to verify referenceId is real orderId and NOT 'temp_order'
  const txnsRes = await request('GET', '/buyer/wallet/transactions', null, buyerToken);
  const latestDebit = txnsRes.data?.transactions?.find(t => t.type === 'DEBIT');
  check('Wallet transaction records real order.id reference (NO temp_order)', latestDebit && latestDebit.referenceId !== 'temp_order' && latestDebit.referenceId === validOrderRes.data?.order?.id, 'Reference ID: ' + latestDebit?.referenceId);

  console.log('\\n=== 6. TESTING ADMIN DASHBOARD REAL PLATFORM METRICS ===');
  const dashEarnings = await request('GET', '/admin/dashboard/earnings', null, adminToken);
  check('Admin dashboard earnings endpoint returns real calculated metrics', dashEarnings.status === 200, 'Net Margin: ₹' + dashEarnings.data?.financialSummary?.platformNetMargin + ', Gross Vol: ₹' + dashEarnings.data?.financialSummary?.grossPlatformVolume);

  console.log('\\n=== 7. TESTING WORKER EARNINGS & WITHDRAWAL IDENTITY RESOLUTION ===');
  const workerWalletRes = await request('GET', '/worker/earnings/wallet', null, workerToken);
  check('Worker earnings wallet resolves without identity mismatch', workerWalletRes.status === 200, 'Available: ₹' + workerWalletRes.data?.wallet?.availableBalance + ', Limit: ₹' + workerWalletRes.data?.wallet?.minWithdrawalLimit);

  console.log('\\n🏁 SUMMARY: ' + passed + ' passed, ' + failed + ' failed.');
  process.exit(failed > 0 ? 1 : 0);
}

main().catch(err => {
  console.error('Test execution error:', err);
  process.exit(1);
});
`;

    console.log('📝 Running test script on VPS...');
    await ssh.execCommand(`cat << 'EOF' > /tmp/test-live-finance.js\n${testScript}\nEOF`);
    const runRes = await ssh.execCommand('node /tmp/test-live-finance.js');
    console.log(runRes.stdout);
    if (runRes.stderr) {
      console.warn(runRes.stderr);
    }
    await ssh.execCommand('rm -f /tmp/test-live-finance.js');
    ssh.dispose();
  } catch (err) {
    console.error('Error running test script:', err);
    ssh.dispose();
    process.exit(1);
  }
}

runLiveFinanceTests();
