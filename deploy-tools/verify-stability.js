const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

(async () => {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    // Wait 10 seconds for processes to stabilize
    console.log('Waiting 10s for processes to stabilize...');
    await new Promise(r => setTimeout(r, 10000));

    console.log('=== PM2 STATUS ===');
    const s = await ssh.execCommand('pm2 status');
    console.log(s.stdout);

    console.log('\n=== DIST DIRECTORY SIZE ===');
    const d = await ssh.execCommand('du -sh /opt/task-engine/dist/ && ls /opt/task-engine/dist/ | head -30');
    console.log(d.stdout);

    console.log('\n=== DIST FILE COUNT ===');
    const c = await ssh.execCommand('find /opt/task-engine/dist -name "*.js" | wc -l');
    console.log('JS files:', c.stdout.trim());

    console.log('\n=== API OUT LOGS (last 15) ===');
    const ao = await ssh.execCommand('tail -15 /root/.pm2/logs/task-engine-api-out-2.log 2>&1');
    console.log(ao.stdout || ao.stderr);

    console.log('\n=== API ERROR LOGS (last 10) ===');
    const ae = await ssh.execCommand('tail -10 /root/.pm2/logs/task-engine-api-error-2.log 2>&1');
    console.log(ae.stdout || ae.stderr || '(empty - no errors)');

    console.log('\n=== WORKER OUT LOGS (last 15) ===');
    const wo = await ssh.execCommand('tail -15 /root/.pm2/logs/task-engine-worker-out-3.log 2>&1');
    console.log(wo.stdout || wo.stderr);

    console.log('\n=== WORKER ERROR LOGS (last 10) ===');
    const we = await ssh.execCommand('tail -10 /root/.pm2/logs/task-engine-worker-error-3.log 2>&1');
    console.log(we.stdout || we.stderr || '(empty - no errors)');

    console.log('\n=== API UPTIME ===');
    const au = await ssh.execCommand('pm2 describe task-engine-api | grep -E "status|uptime|restart"');
    console.log(au.stdout);

    console.log('\n=== WORKER UPTIME ===');
    const wu = await ssh.execCommand('pm2 describe task-engine-worker | grep -E "status|uptime|restart"');
    console.log(wu.stdout);

    ssh.dispose();
  } catch (err) {
    console.error('Error:', err.message);
    ssh.dispose();
  }
})();
