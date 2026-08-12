const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function diagnose() {
    await ssh.connect({
      host: '95.179.178.6',
      username: 'root',
      password: 'i_G72#y}(6gACDDU'
    });
    console.log('=== Connected to VPS ===\n');

    // 1. PM2 status
    console.log('--- PM2 STATUS ---');
    const pm2Status = await ssh.execCommand('pm2 list');
    console.log(pm2Status.stdout);
    console.log(pm2Status.stderr);

    // 2. PM2 describe for detailed info (restart count, uptime, etc.)
    console.log('\n--- PM2 DESCRIBE ---');
    const pm2Desc = await ssh.execCommand('pm2 describe task-engine');
    console.log(pm2Desc.stdout);
    console.log(pm2Desc.stderr);

    // 3. Error logs (last 200 lines)
    console.log('\n--- ERROR LOGS (last 200 lines) ---');
    const errorLogs = await ssh.execCommand('tail -n 200 /root/.pm2/logs/task-engine-error-0.log 2>/dev/null || echo "No error-0.log found"');
    console.log(errorLogs.stdout);

    // 4. Out logs (last 100 lines) 
    console.log('\n--- OUT LOGS (last 100 lines) ---');
    const outLogs = await ssh.execCommand('tail -n 100 /root/.pm2/logs/task-engine-out-0.log 2>/dev/null || echo "No out-0.log found"');
    console.log(outLogs.stdout);

    // 5. System resources
    console.log('\n--- SYSTEM RESOURCES ---');
    const freeRam = await ssh.execCommand('free -h');
    console.log('RAM:', freeRam.stdout);
    
    const diskUsage = await ssh.execCommand('df -h /');
    console.log('Disk:', diskUsage.stdout);

    // 6. Check dmesg for OOM killer
    console.log('\n--- OOM KILLER CHECK ---');
    const oom = await ssh.execCommand('dmesg | grep -i "oom\\|killed process" | tail -n 10');
    console.log(oom.stdout || 'No OOM events found');

    // 7. Check uptime and load
    console.log('\n--- UPTIME ---');
    const uptime = await ssh.execCommand('uptime');
    console.log(uptime.stdout);

    ssh.dispose();
}
diagnose().catch(err => {
    console.error('SSH Error:', err.message);
    process.exit(1);
});
