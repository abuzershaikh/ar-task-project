const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function testVpsNow() {
    await ssh.connect({
      host: '95.179.178.6',
      username: 'root',
      password: 'i_G72#y}(6gACDDU'
    });
    console.log('=== Checking Current VPS Status ===\n');

    // 1. PM2 Status
    const pm2List = await ssh.execCommand('pm2 jlist');
    const apps = JSON.parse(pm2List.stdout || '[]');
    console.log('PM2 Apps:');
    apps.forEach(app => {
        console.log(`- ID: ${app.pm_id}, Name: ${app.name}, Status: ${app.pm2_env.status}, Restarts: ${app.pm2_env.restart_time}, Uptime: ${Math.round((Date.now() - app.pm2_env.pm_uptime)/1000)}s`);
    });

    // 2. Test API Health Endpoint
    const health = await ssh.execCommand('curl -s http://localhost:3000/api/v1/health');
    console.log('\nHealth check (http://localhost:3000/api/v1/health):', health.stdout);

    // 3. Tail latest 50 error logs
    console.log('\n--- Recent PM2 Error Logs (last 50 lines) ---');
    const errLog = await ssh.execCommand('tail -n 50 /root/.pm2/logs/task-engine-error-0.log');
    console.log(errLog.stdout || '(Empty)');

    // 4. Tail latest 30 out logs
    console.log('\n--- Recent PM2 Out Logs (last 30 lines) ---');
    const outLog = await ssh.execCommand('tail -n 30 /root/.pm2/logs/task-engine-out-0.log');
    console.log(outLog.stdout || '(Empty)');

    ssh.dispose();
}
testVpsNow().catch(err => console.error(err));
