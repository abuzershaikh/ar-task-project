const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function checkMore() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== TOP DIRECTORIES IN / ===');
    const duRoot = await ssh.execCommand('du -sh /* 2>/dev/null | sort -hr | head -n 12');
    console.log(duRoot.stdout);

    console.log('=== MYSQL DB SIZE ===');
    const mysqlSize = await ssh.execCommand('du -sh /var/lib/mysql 2>/dev/null');
    console.log(mysqlSize.stdout);

    console.log('=== DOCKER / CONTAINER SIZE ===');
    const dockerSize = await ssh.execCommand('du -sh /var/lib/docker 2>/dev/null');
    console.log(dockerSize.stdout);

    ssh.dispose();
  } catch (err) {
    console.error('Error:', err.message);
  } finally {
    process.exit(0);
  }
}

checkMore();
