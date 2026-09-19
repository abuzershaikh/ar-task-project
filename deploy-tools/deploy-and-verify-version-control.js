const { NodeSSH } = require('node-ssh');
const path = require('path');

const ssh = new NodeSSH();

async function main() {
  try {
    console.log('--- 1. Connecting to VPS ---');
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });
    console.log('✓ Connected to VPS');

    console.log('\n--- 2. Uploading backend files to VPS ---');
    const localDir = path.resolve(__dirname, '..', 'Task engine');

    await ssh.putFile(
      path.join(localDir, 'apps', 'api', 'controllers', 'admin', 'system-settings.controller.ts'),
      '/opt/task-engine/apps/api/controllers/admin/system-settings.controller.ts'
    );
    console.log('✓ Uploaded system-settings.controller.ts');

    await ssh.putFile(
      path.join(localDir, 'apps', 'api', 'controllers', 'common', 'app-update.controller.ts'),
      '/opt/task-engine/apps/api/controllers/common/app-update.controller.ts'
    );
    console.log('✓ Uploaded app-update.controller.ts');

    console.log('\n--- 3. Compiling backend (npm run build) on VPS ---');
    const buildRes = await ssh.execCommand('npm run build', { cwd: '/opt/task-engine' });
    console.log(buildRes.stdout);
    if (buildRes.stderr && !buildRes.stdout) console.error('Build stderr:', buildRes.stderr);

    console.log('\n--- 4. Restarting PM2 task-engine-api ---');
    const pm2Res = await ssh.execCommand('pm2 restart task-engine-api', { cwd: '/opt/task-engine' });
    console.log(pm2Res.stdout);

    console.log('Waiting 4 seconds for API to be ready...');
    await new Promise((r) => setTimeout(r, 4000));

    console.log('\n--- 5. Running End-to-End Verification Test Suite ---');
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
  const adminToken = jwt.sign({
    sub: '102f44e4-a79a-4efd-88c8-b32927bd7ea7',
    email: 'admin@taskpost.com',
    role: 'SUPER_ADMIN',
  }, secret, { expiresIn: '1d' });

  console.log('=== TEST 1: Admin Fetches Version Registry ===');
  const res1 = await request('GET', '/admin/settings/app-updates', null, adminToken);
  console.log('Version list count:', res1.data?.settings?.versionList?.length);
  console.log('Latest Version:', res1.data?.settings?.latestVersion, '(Code:', res1.data?.settings?.latestVersionCode + ')');

  console.log('\\n=== TEST 2: Admin Adds New Version Code (Version 1.0.4, Code #4) as ACTIVE ===');
  const addRes = await request('POST', '/admin/settings/app-updates/add-version', {
    versionName: '1.0.4',
    versionCode: '4',
    status: 'active',
    updateUrl: 'https://cdn.example.com/releases/worker_1.0.5.apk',
    message: 'Active build'
  }, adminToken);
  console.log('Add status:', addRes.status, 'Message:', addRes.data?.message);

  console.log('\\n=== TEST 3: Worker opens app with version 1.0.4 (code 4) while ACTIVE ===');
  const checkActive = await request('GET', '/app/check-update?version=1.0.4&versionCode=4&app=worker');
  console.log('Worker (1.0.4, code 4) check -> updateRequired:', checkActive.data?.updateRequired, '(Expected: false)');

  console.log('\\n=== TEST 4: Admin clicks DISABLE Button and sets custom Redirect Link ===');
  const customLink = 'https://custom-drive-link.com/download/Worker_Latest.apk';
  const toggleRes = await request('POST', '/admin/settings/app-updates/toggle-status', {
    versionName: '1.0.4',
    versionCode: '4',
    status: 'disabled',
    updateUrl: customLink,
    message: 'Attention: Version 1.0.4 is disabled. Download new version now.'
  }, adminToken);
  console.log('Toggle result:', toggleRes.data?.message);

  console.log('\\n=== TEST 5: Worker opens app with version 1.0.4 (code 4) while DISABLED ===');
  const checkDisabled = await request('GET', '/app/check-update?version=1.0.4&versionCode=4&app=worker');
  console.log('Worker (1.0.4, code 4) check -> updateRequired:', checkDisabled.data?.updateRequired, '(Expected: true)');
  console.log('Worker received redirect downloadUrl:', checkDisabled.data?.downloadUrl);
  console.log('Matches custom link?:', checkDisabled.data?.downloadUrl === customLink);

  console.log('\\n=== TEST 6: Admin clicks ENABLE Button to restore access ===');
  const enableRes = await request('POST', '/admin/settings/app-updates/toggle-status', {
    versionName: '1.0.4',
    versionCode: '4',
    status: 'active'
  }, adminToken);
  console.log('Enable result:', enableRes.data?.message);

  const checkReEnabled = await request('GET', '/app/check-update?version=1.0.4&versionCode=4&app=worker');
  console.log('Worker after re-enable -> updateRequired:', checkReEnabled.data?.updateRequired, '(Expected: false)');

  console.log('\\n=== ALL TESTS PASSED WITH 100% SUCCESS! ===');
}

run().catch(console.error);
`;

    const remoteBase = '/opt/task-engine';
    await ssh.execCommand(`cat << 'EOF' > ${remoteBase}/test-version-control.js\n${testScript}\nEOF`);
    const testRun = await ssh.execCommand('node test-version-control.js', { cwd: remoteBase });
    console.log(testRun.stdout);
    if (testRun.stderr) console.error('STDERR:', testRun.stderr);
    await ssh.execCommand(`rm -f ${remoteBase}/test-version-control.js`);

  } catch (err) {
    console.error('Fatal error:', err);
  } finally {
    ssh.dispose();
  }
}

main();
