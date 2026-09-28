const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== DISK USAGE ===');
    const df = await ssh.execCommand('df -h /');
    console.log(df.stdout);

    console.log('=== MEMORY USAGE ===');
    const mem = await ssh.execCommand('free -h');
    console.log(mem.stdout);

    console.log('=== SYSTEM LOAD ===');
    const uptime = await ssh.execCommand('uptime');
    console.log(uptime.stdout);

  } catch (e) {
    console.error('Error:', e.message);
  } finally {
    ssh.dispose();
    process.exit(0);
  }
}

run();
