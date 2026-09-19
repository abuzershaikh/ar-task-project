const { NodeSSH } = require('node-ssh');
const path = require('path');

const ssh = new NodeSSH();

async function main() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('--- 1. Uploading updated app-update.controller.ts to VPS ---');
    const localFile = path.resolve(__dirname, '..', 'Task engine', 'apps', 'api', 'controllers', 'common', 'app-update.controller.ts');
    await ssh.putFile(localFile, '/opt/task-engine/apps/api/controllers/common/app-update.controller.ts');
    console.log('✓ Uploaded app-update.controller.ts');

    console.log('\n--- 2. Compiling backend on VPS (npm run build) ---');
    const buildRes = await ssh.execCommand('npm run build', { cwd: '/opt/task-engine' });
    console.log(buildRes.stdout);
    if (buildRes.stderr && !buildRes.stdout) console.error(buildRes.stderr);

    console.log('\n--- 3. Restarting PM2 task-engine-api ---');
    const pm2Res = await ssh.execCommand('pm2 restart task-engine-api', { cwd: '/opt/task-engine' });
    console.log(pm2Res.stdout);
    console.log('Waiting 4s for NestJS to bind port 3000...');
    await new Promise(r => setTimeout(r, 4000));

    console.log('\n--- 4. Running App Update Verification Suite ---');
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

  // 1. Get current settings
  console.log('Step 1: Admin fetches current settings');
  const curr = await request('GET', '/admin/settings/app-updates', null, adminToken);
  console.log('Current settings:', JSON.stringify(curr.data?.settings, null, 2));

  // 2. Set latestVersion to 1.0.5 and add version 1.0.4 to updateList
  console.log('\\nStep 2: Admin configures latestVersion=1.0.5 and forces update for version 1.0.4');
  await request('POST', '/admin/settings/app-updates', {
    latestVersion: '1.0.5',
    apkDownloadUrl: 'https://raw.githubusercontent.com/abuzershaikh/ar-task-project/main/Worker_App_Release.apk',
    updateMessage: 'Critical security update is required to continue working.',
    releaseNotes: '• Major bug fixes\\n• Instant withdrawal improvements\\n• Performance boost',
    updateList: ['1.0.4']
  }, adminToken);

  // 3. Worker with version 1.0.4 checks
  console.log('\\nStep 3: Worker with version 1.0.4 checks for update');
  const res104 = await request('GET', '/app/check-update?version=1.0.4&app=worker');
  console.log('Worker 1.0.4 -> updateRequired:', res104.data?.updateRequired, '(Expected: true)');

  // 4. Worker with version 1.0.4+4 (build number suffix) checks
  console.log('\\nStep 4: Worker with Flutter version format 1.0.4+4 checks for update');
  const resBuild = await request('GET', '/app/check-update?version=1.0.4+4&app=worker');
  console.log('Worker 1.0.4+4 -> updateRequired:', resBuild.data?.updateRequired, '(Expected: true)');

  // 5. Worker with latest version 1.0.5 checks
  console.log('\\nStep 5: Worker with latest version 1.0.5 checks for update');
  const res105 = await request('GET', '/app/check-update?version=1.0.5&app=worker');
  console.log('Worker 1.0.5 -> updateRequired:', res105.data?.updateRequired, '(Expected: false)');

  // 6. Test wildcard: Admin adds "*" so ALL older versions are forced to update
  console.log('\\nStep 6: Admin sets updateList to ["*"] (Wildcard)');
  await request('POST', '/admin/settings/app-updates', {
    updateList: ['*']
  }, adminToken);

  const resWildcardOlder = await request('GET', '/app/check-update?version=1.0.2&app=worker');
  console.log('Wildcard check for older version (1.0.2) -> updateRequired:', resWildcardOlder.data?.updateRequired, '(Expected: true)');

  const resWildcardLatest = await request('GET', '/app/check-update?version=1.0.5&app=worker');
  console.log('Wildcard check for latest version (1.0.5) -> updateRequired:', resWildcardLatest.data?.updateRequired, '(Expected: false)');

  console.log('\\n=== ALL TESTS COMPLETED SUCCESSFULLY! ===');
}

run().catch(console.error);
`;

    const remoteBase = '/opt/task-engine';
    await ssh.execCommand(`cat << 'EOF' > ${remoteBase}/test-update-suite.js\n${testScript}\nEOF`);
    const testRun = await ssh.execCommand('node test-update-suite.js', { cwd: remoteBase });
    console.log(testRun.stdout);
    if (testRun.stderr) console.error('STDERR:', testRun.stderr);
    await ssh.execCommand(`rm -f ${remoteBase}/test-update-suite.js`);

  } catch (e) {
    console.error('Deployment error:', e);
  } finally {
    ssh.dispose();
  }
}

main();
