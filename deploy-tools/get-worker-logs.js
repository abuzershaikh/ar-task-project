const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

(async () => {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== CHECK IF WORKER.JS EXISTS ===');
    const f = await ssh.execCommand('ls -la /opt/task-engine/dist/worker.js 2>&1');
    console.log(f.stdout || f.stderr);

    console.log('\n=== WORKER ERROR LOG FILE DIRECTLY ===');
    const e = await ssh.execCommand('tail -100 /root/.pm2/logs/task-engine-worker-error-3.log 2>&1');
    console.log(e.stdout || e.stderr);

    console.log('\n=== WORKER OUT LOG FILE DIRECTLY ===');
    const o = await ssh.execCommand('tail -30 /root/.pm2/logs/task-engine-worker-out-3.log 2>&1');
    console.log(o.stdout || o.stderr);

    console.log('\n=== API ENTRY POINT CHECK ===');
    const a = await ssh.execCommand('ls -la /opt/task-engine/dist/main.js 2>&1');
    console.log(a.stdout || a.stderr);

    console.log('\n=== DIST DIRECTORY ===');
    const d = await ssh.execCommand('ls -la /opt/task-engine/dist/ 2>&1 | head -30');
    console.log(d.stdout || d.stderr);

    console.log('\n=== PACKAGE.JSON SCRIPTS ===');
    const p = await ssh.execCommand('cat /opt/task-engine/package.json | grep -A 20 scripts 2>&1');
    console.log(p.stdout || p.stderr);

    ssh.dispose();
  } catch (err) {
    console.error('Error:', err.message);
    ssh.dispose();
  }
})();
