const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function testWithdrawalLifecycle() {
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
  let passed = 0;
  let failed = 0;

  function assert(condition, message) {
    if (condition) {
      console.log('   ✅ PASS:', message);
      passed++;
    } else {
      console.error('   ❌ FAIL:', message);
      failed++;
    }
  }

  // 1. Admin login
  const adminRes = await request('POST', '/auth/login', {
    email: 'admin@taskpost.com',
    password: 'Admin@123456',
  });
  const adminToken = adminRes.data?.data?.accessToken;
  assert(adminToken, 'Admin authenticated');

  // 2. Query admin payouts pending
  const pendingRes = await request('GET', '/admin/payouts/pending', null, adminToken);
  assert(pendingRes.status === 200 && Array.isArray(pendingRes.data?.withdrawals), 'Admin get pending payouts succeeds');

  // 3. Get payout config
  const configRes = await request('GET', '/admin/payouts/config', null, adminToken);
  assert(configRes.status === 200 && typeof configRes.data?.minWithdrawalLimit === 'number', 'Admin get payout config succeeds');

  console.log('\\n🏁 Admin Payout Verification: ' + passed + ' passed, ' + failed + ' failed.');
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
`;

    const remoteBase = '/opt/task-engine';
    await ssh.execCommand(`cat << 'EOF' > ${remoteBase}/test-payout-admin.js\n${testScript}\nEOF`);
    const testRes = await ssh.execCommand(`node test-payout-admin.js`, { cwd: remoteBase });
    console.log(testRes.stdout);
    if (testRes.stderr && !testRes.stderr.includes('Debugger')) {
      console.warn('Test warnings/errors:', testRes.stderr);
    }

    await ssh.execCommand(`rm -f ${remoteBase}/test-payout-admin.js`);
    ssh.dispose();
  } catch (err) {
    console.error('Test error:', err);
    ssh.dispose();
    process.exit(1);
  }
}

testWithdrawalLifecycle();
