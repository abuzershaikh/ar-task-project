const { NodeSSH } = require('node-ssh');
const path = require('path');
const ssh = new NodeSSH();

async function main() {
  try {
    console.log('Connecting to VPS...');
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    const localBase = 'e:/pc2/android  project/Task  project/ar-task-project/Task engine';
    const remoteBase = '/opt/task-engine';

    console.log('Uploading updated controllers & services...');
    await ssh.putFile(
      path.join(localBase, 'apps/api/controllers/admin/dashboard.controller.ts'),
      `${remoteBase}/apps/api/controllers/admin/dashboard.controller.ts`
    );
    await ssh.putFile(
      path.join(localBase, 'apps/api/controllers/admin/worker-management.controller.ts'),
      `${remoteBase}/apps/api/controllers/admin/worker-management.controller.ts`
    );
    await ssh.putFile(
      path.join(localBase, 'apps/api/controllers/admin/buyer-management.controller.ts'),
      `${remoteBase}/apps/api/controllers/admin/buyer-management.controller.ts`
    );
    await ssh.putFile(
      path.join(localBase, 'shared/services/user-sync.service.ts'),
      `${remoteBase}/shared/services/user-sync.service.ts`
    );

    console.log('Building NestJS backend on VPS...');
    const bRes = await ssh.execCommand('npx nest build', { cwd: remoteBase });
    console.log('Build Output:', bRes.stdout || 'Done');
    if (bRes.stderr) console.log('Build Stderr:', bRes.stderr);

    console.log('Restarting PM2...');
    await ssh.execCommand('pm2 restart task-engine-api task-engine-worker');
    console.log('PM2 restarted successfully!');

    // Wait 3 seconds for server to boot
    await new Promise(r => setTimeout(r, 3000));

    const authHeaders = '-H "x-user-email: admin@taskpost.com" -H "x-user-id: 102f44e4-a79a-4efd-88c8-b32927bd7ea7" -H "x-user-role: SUPER_ADMIN"';

    console.log('\n--- 1. VERIFYING ADMIN DASHBOARD API ---');
    const dashRes = await ssh.execCommand(`curl -s ${authHeaders} http://127.0.0.1:3000/api/v1/admin/dashboard`);
    console.log('Dashboard Response:');
    try {
      const parsed = JSON.parse(dashRes.stdout);
      console.log(JSON.stringify(parsed.dashboard?.users, null, 2));
    } catch {
      console.log(dashRes.stdout);
    }

    console.log('\n--- 2. VERIFYING ADMIN WORKERS DASHBOARD API ---');
    const wDashRes = await ssh.execCommand(`curl -s ${authHeaders} http://127.0.0.1:3000/api/v1/admin/dashboard/workers`);
    try {
      const parsed = JSON.parse(wDashRes.stdout);
      console.log(JSON.stringify(parsed.workersSummary, null, 2));
    } catch {
      console.log(wDashRes.stdout);
    }

    console.log('\n--- 3. VERIFYING LIST ALL WORKERS ---');
    const allWorkersRes = await ssh.execCommand(`curl -s ${authHeaders} http://127.0.0.1:3000/api/v1/admin/workers`);
    try {
      const parsed = JSON.parse(allWorkersRes.stdout);
      console.log(`Total workers returned: ${parsed.workers?.length}`);
      const active = parsed.workers.filter(w => w.status === 'ACTIVE').length;
      const inactive = parsed.workers.filter(w => w.status === 'INACTIVE').length;
      console.log(`Computed in workers list: Active=${active}, Inactive=${inactive}`);
      if (parsed.workers.length > 0) {
        console.log('Sample worker[0]:', {
          id: parsed.workers[0].id,
          name: parsed.workers[0].name,
          status: parsed.workers[0].status,
          activityStatus: parsed.workers[0].activityStatus,
          lastActiveAt: parsed.workers[0].lastActiveAt,
        });
      }
    } catch {
      console.log(allWorkersRes.stdout);
    }

    console.log('\n--- 4. VERIFYING FILTER INACTIVE WORKERS API ---');
    const inactiveWorkersRes = await ssh.execCommand(`curl -s ${authHeaders} "http://127.0.0.1:3000/api/v1/admin/workers?status=INACTIVE"`);
    try {
      const parsed = JSON.parse(inactiveWorkersRes.stdout);
      console.log(`Inactive workers returned: ${parsed.workers?.length}`);
      if (parsed.workers && parsed.workers.length > 0) {
        console.log('Sample Inactive worker[0]:', {
          id: parsed.workers[0].id,
          name: parsed.workers[0].name,
          status: parsed.workers[0].status,
          activityStatus: parsed.workers[0].activityStatus,
          lastActiveAt: parsed.workers[0].lastActiveAt,
        });
      }
    } catch {
      console.log(inactiveWorkersRes.stdout);
    }

    console.log('\n--- 5. VERIFYING FILTER ACTIVE WORKERS API ---');
    const activeWorkersRes = await ssh.execCommand(`curl -s ${authHeaders} "http://127.0.0.1:3000/api/v1/admin/workers?status=ACTIVE"`);
    try {
      const parsed = JSON.parse(activeWorkersRes.stdout);
      console.log(`Active workers returned: ${parsed.workers?.length}`);
      if (parsed.workers && parsed.workers.length > 0) {
        console.log('Sample Active worker[0]:', {
          id: parsed.workers[0].id,
          name: parsed.workers[0].name,
          status: parsed.workers[0].status,
          activityStatus: parsed.workers[0].activityStatus,
          lastActiveAt: parsed.workers[0].lastActiveAt,
        });
      }
    } catch {
      console.log(activeWorkersRes.stdout);
    }

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

main();
