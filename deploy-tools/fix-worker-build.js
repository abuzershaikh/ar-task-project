const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();
const fs = require('fs');
const path = require('path');

const BASE = path.resolve(__dirname, '../Task engine');

async function deploy() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });
    console.log('✅ Connected to VPS');

    // 1. Upload fixed config files
    console.log('\n=== UPLOADING FIXES ===');
    
    // nest-cli.json
    await ssh.putFile(
      path.join(BASE, 'nest-cli.json'),
      '/opt/task-engine/nest-cli.json'
    );
    console.log('  ✅ nest-cli.json uploaded (webpack: false)');

    // package.json
    await ssh.putFile(
      path.join(BASE, 'package.json'),
      '/opt/task-engine/package.json'
    );
    console.log('  ✅ package.json uploaded (clean build script)');

    // worker.ts
    await ssh.putFile(
      path.join(BASE, 'worker.ts'),
      '/opt/task-engine/worker.ts'
    );
    console.log('  ✅ worker.ts uploaded');

    // 2. Rebuild on VPS
    console.log('\n=== REBUILDING ON VPS ===');
    const build = await ssh.execCommand('cd /opt/task-engine && npm run build 2>&1', { 
      cwd: '/opt/task-engine',
      timeout: 120000 
    });
    console.log(build.stdout ? build.stdout.substring(build.stdout.length - 2000) : '');
    if (build.stderr) console.log('STDERR:', build.stderr.substring(0, 2000));

    // 3. Verify worker.js was created
    console.log('\n=== VERIFY WORKER.JS EXISTS ===');
    const verify = await ssh.execCommand('ls -la /opt/task-engine/dist/worker.js /opt/task-engine/dist/main.js 2>&1');
    console.log(verify.stdout || verify.stderr);

    // 4. Restart PM2
    console.log('\n=== RESTARTING PM2 SERVICES ===');
    const restart = await ssh.execCommand('cd /opt/task-engine && pm2 restart task-engine-api task-engine-worker 2>&1');
    console.log(restart.stdout || restart.stderr);

    // 5. Wait and check status
    await new Promise(r => setTimeout(r, 5000));
    console.log('\n=== PM2 STATUS (after 5s) ===');
    const status = await ssh.execCommand('pm2 status');
    console.log(status.stdout);

    // 6. Check for errors
    console.log('\n=== WORKER ERROR CHECK ===');
    const workerErr = await ssh.execCommand('tail -20 /root/.pm2/logs/task-engine-worker-error-3.log 2>&1');
    console.log(workerErr.stdout || workerErr.stderr || '(no errors)');

    console.log('\n=== API ERROR CHECK ===');
    const apiErr = await ssh.execCommand('tail -20 /root/.pm2/logs/task-engine-api-error-2.log 2>&1');
    console.log(apiErr.stdout || apiErr.stderr || '(no errors)');

    ssh.dispose();
  } catch (err) {
    console.error('❌ Error:', err.message);
    ssh.dispose();
  }
}

deploy();
