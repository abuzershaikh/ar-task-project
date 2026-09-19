const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function runTest() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });

    console.log('--- 1. Check Available Tasks for sonathe333@gmail.com ---');
    const resSona = await ssh.execCommand('curl -s -H "x-user-id: MYDovhuR8zcbLlvazaAG8qdWLXr1" -H "x-user-email: sonathe333@gmail.com" -H "x-user-role: WORKER" http://127.0.0.1:3000/api/v1/worker/tasks/available');
    const dataSona = JSON.parse(resSona.stdout);
    console.log('Available tasks count for sonathe:', (dataSona.tasks || []).length);

    const appsSona = new Set();
    const urlsSona = new Set();
    let dupSona = 0;
    for (const t of (dataSona.tasks || [])) {
      const req = t.requirements || {};
      const pkg = (req.packageId || t.packageId || '').toLowerCase();
      const url = req.targetUrl || req.url || t.targetUrl || '';
      if (pkg) {
        if (appsSona.has(pkg)) {
          console.log('Duplicate app found for sonathe:', pkg);
          dupSona++;
        }
        appsSona.add(pkg);
      }
      if (url) {
        if (urlsSona.has(url)) {
          console.log('Duplicate URL found for sonathe:', url);
          dupSona++;
        }
        urlsSona.add(url);
      }
    }
    if (dupSona === 0) {
      console.log('✅ ALL available tasks for sonathe are 100% DISTINCT (no duplicate apps or URLs)!');
    }

    console.log('\n--- 2. Check Available Tasks for sufieditz@gmail.com ---');
    const res = await ssh.execCommand('curl -s -H "x-user-id: kQzd3bZD7pgA908xGE6NoGogetB3" -H "x-user-email: sufieditz@gmail.com" -H "x-user-role: WORKER" http://127.0.0.1:3000/api/v1/worker/tasks/available');
    const data = JSON.parse(res.stdout);
    console.log('Available tasks count:', (data.tasks || []).length);

    const apps = new Set();
    const urls = new Set();
    let duplicates = 0;

    for (const t of (data.tasks || [])) {
      const req = t.requirements || {};
      const pkg = (req.packageId || t.packageId || '').toLowerCase();
      const url = req.targetUrl || req.url || t.targetUrl || '';

      if (pkg) {
        if (apps.has(pkg)) {
          console.log('Duplicate app found in available tasks:', pkg);
          duplicates++;
        }
        apps.add(pkg);
      }
      if (url) {
        if (urls.has(url)) {
          console.log('Duplicate URL found in available tasks:', url);
          duplicates++;
        }
        urls.add(url);
      }
    }

    if (duplicates === 0) {
      console.log('✅ ALL available tasks are 100% DISTINCT (no duplicate apps or URLs)!');
    }

    console.log('\n--- 2. Check Notifications Endpoint for sufieditz@gmail.com ---');
    const notifRes = await ssh.execCommand('curl -s -H "x-user-id: kQzd3bZD7pgA908xGE6NoGogetB3" -H "x-user-email: sufieditz@gmail.com" -H "x-user-role: WORKER" http://127.0.0.1:3000/api/v1/worker/notifications');
    const notifs = JSON.parse(notifRes.stdout);
    console.log('Filtered Notifications count:', (notifs.notifications || []).length);

    console.log('\n--- 3. Check Notifications Unread Count for sufieditz@gmail.com ---');
    const unreadRes = await ssh.execCommand('curl -s -H "x-user-id: kQzd3bZD7pgA908xGE6NoGogetB3" -H "x-user-email: sufieditz@gmail.com" -H "x-user-role: WORKER" http://127.0.0.1:3000/api/v1/worker/notifications/unread-count');
    console.log('Unread Count Response:', unreadRes.stdout);

  } catch (err) {
    console.error('Test Error:', err);
  } finally {
    ssh.dispose();
  }
}

runTest();
