const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function runAudit() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== STARTING ADMIN APP vs TASK ENGINE AUDIT ===\n');

    // Step 1: Admin Login
    console.log('--- 1. Testing Admin Authentication (/api/v1/auth/login) ---');
    const loginRes = await ssh.execCommand(`curl -s -X POST http://localhost:3000/api/v1/auth/login -H "Content-Type: application/json" -d '{"email":"snapbizux@gmail.com","password":"80978097"}'`);
    let token = null;
    try {
      const parsed = JSON.parse(loginRes.stdout);
      token = parsed.data?.accessToken || parsed.data?.token || parsed.token || parsed.accessToken;
      console.log('Login Response Status:', parsed.success ? 'SUCCESS (true)' : 'FAILED');
      console.log('User Role:', parsed.data?.user?.role || parsed.data?.role);
      console.log('Token Received:', token ? 'YES (Valid Bearer JWT)' : 'NO');
    } catch (e) {
      console.error('Failed to parse login response:', loginRes.stdout);
      return;
    }

    if (!token) {
      console.error('No token obtained. Aborting audit.');
      return;
    }

    // Step 2: Audit Endpoints
    const endpointsToTest = [
      { name: 'Dashboard Overview', method: 'GET', url: '/admin/dashboard' },
      { name: 'Dashboard Orders', method: 'GET', url: '/admin/dashboard/orders' },
      { name: 'Dashboard Tasks', method: 'GET', url: '/admin/dashboard/tasks' },
      { name: 'Dashboard Workers', method: 'GET', url: '/admin/dashboard/workers' },
      { name: 'Dashboard Buyers', method: 'GET', url: '/admin/dashboard/buyers' },
      { name: 'Dashboard Earnings', method: 'GET', url: '/admin/dashboard/earnings' },
      { name: 'Dashboard Payouts', method: 'GET', url: '/admin/dashboard/payouts' },
      { name: 'Workers List', method: 'GET', url: '/admin/workers' },
      { name: 'Buyers List', method: 'GET', url: '/admin/buyers' },
      { name: 'Orders List', method: 'GET', url: '/admin/orders' },
      { name: 'Services Catalog (/admin/services)', method: 'GET', url: '/admin/services' },
      { name: 'Services Catalog (/admin/service-catalog)', method: 'GET', url: '/admin/service-catalog' },
      { name: 'Matching Config', method: 'GET', url: '/admin/matching/config' },
      { name: 'Pending Reviews', method: 'GET', url: '/admin/reviews/pending' },
      { name: 'Pending KYC', method: 'GET', url: '/admin/kyc/pending' },
      { name: 'Pending Payouts', method: 'GET', url: '/admin/payouts/pending' },
      { name: 'Analytics Overview', method: 'GET', url: '/admin/analytics/overview' },
      { name: 'Risk Dashboard', method: 'GET', url: '/admin/risk/dashboard' },
      { name: 'System Settings', method: 'GET', url: '/admin/settings' },
      { name: 'Audit Logs', method: 'GET', url: '/admin/audit-logs' },
      { name: 'Notifications', method: 'GET', url: '/admin/notifications' },
      { name: 'App Version Control', method: 'GET', url: '/admin/app-version' }
    ];

    console.log('\n--- 2. Auditing Admin Endpoints on Task Engine ---');
    const results = [];

    for (const ep of endpointsToTest) {
      const cmd = `curl -s -w "\\n---HTTP_STATUS:%{http_code}---" -H "Authorization: Bearer ${token}" -H "Accept: application/json" http://localhost:3000/api/v1${ep.url}`;
      const res = await ssh.execCommand(cmd);
      const parts = res.stdout.split('---HTTP_STATUS:');
      const body = parts[0] ? parts[0].trim() : '';
      const status = parts[1] ? parts[1].replace('---', '').trim() : 'UNKNOWN';

      let isSuccess = false;
      let dataSummary = '';
      try {
        const json = JSON.parse(body);
        isSuccess = json.success !== false && (status === '200' || status === '201');
        if (Array.isArray(json.data)) {
          dataSummary = `Array (${json.data.length} items)`;
        } else if (json.data && typeof json.data === 'object') {
          dataSummary = `Object (${Object.keys(json.data).slice(0, 4).join(', ')})`;
        } else if (json.message) {
          dataSummary = json.message;
        } else {
          dataSummary = typeof json;
        }
      } catch (e) {
        dataSummary = body.substring(0, 60);
      }

      results.push({
        name: ep.name,
        endpoint: ep.url,
        status: status,
        ok: isSuccess,
        summary: dataSummary
      });

      console.log(`[${status}] ${ep.name.padEnd(36)} -> ${ep.url.padEnd(30)} | ${dataSummary}`);
    }

  } catch (err) {
    console.error('Audit Error:', err);
  } finally {
    ssh.dispose();
  }
}

runAudit();
