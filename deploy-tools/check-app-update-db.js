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
  const adminToken = jwt.sign({
    sub: '102f44e4-a79a-4efd-88c8-b32927bd7ea7',
    email: 'admin@taskpost.com',
    role: 'SUPER_ADMIN',
  }, secret, { expiresIn: '1d' });

  console.log('--- 1. Admin gets current app update settings ---');
  const getRes = await request('GET', '/admin/settings/app-updates', null, adminToken);
  console.log('Current settings:', JSON.stringify(getRes.data, null, 2));

  console.log('\\n--- 2. Admin adds version 1.0.0 to forced update list ---');
  const addRes = await request('POST', '/admin/settings/app-updates/add-version', { version: '1.0.0' }, adminToken);
  console.log('Add version result:', JSON.stringify(addRes.data, null, 2));

  console.log('\\n--- 3. Worker with version 1.0.0 checks for update ---');
  const checkV1 = await request('GET', '/app/check-update?version=1.0.0&app=worker');
  console.log('Worker v1.0.0 check result:', JSON.stringify(checkV1.data, null, 2));
  console.log('>>> IS UPDATE REQUIRED FOR v1.0.0?:', checkV1.data?.updateRequired);

  console.log('\\n--- 4. Worker with version 1.0.1 checks for update ---');
  const checkV101 = await request('GET', '/app/check-update?version=1.0.1&app=worker');
  console.log('Worker v1.0.1 check result:', JSON.stringify(checkV101.data, null, 2));
  console.log('>>> IS UPDATE REQUIRED FOR v1.0.1?:', checkV101.data?.updateRequired);

  console.log('\\n--- 5. Admin removes version 1.0.0 from forced update list ---');
  const removeRes = await request('DELETE', '/admin/settings/app-updates/remove-version/1.0.0', null, adminToken);
  console.log('Remove version result:', JSON.stringify(removeRes.data, null, 2));

  console.log('\\n--- 6. Worker with version 1.0.0 checks again after removal ---');
  const checkAfter = await request('GET', '/app/check-update?version=1.0.0&app=worker');
  console.log('Worker v1.0.0 check after removal:', JSON.stringify(checkAfter.data, null, 2));
  console.log('>>> IS UPDATE REQUIRED FOR v1.0.0 AFTER REMOVAL?:', checkAfter.data?.updateRequired);
}

run().catch(console.error);
`;

    const remoteBase = '/opt/task-engine';
    await ssh.execCommand(`cat << 'EOF' > ${remoteBase}/test-update-flow.js\n${testScript}\nEOF`);
    const res = await ssh.execCommand(`node test-update-flow.js`, { cwd: remoteBase });
    console.log(res.stdout);
    if (res.stderr) console.error('STDERR:', res.stderr);

    await ssh.execCommand(`rm -f ${remoteBase}/test-update-flow.js`);
  } catch (e) {
    console.error(e);
  } finally {
    ssh.dispose();
  }
}

main();
