const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function checkMore() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== DU IN /OPT/WAZIPER-ENGINE ===');
    const duWaz = await ssh.execCommand('du -sh /opt/waziper-engine/* 2>/dev/null | sort -hr | head -n 10');
    console.log(duWaz.stdout);

    console.log('=== PM2 LOGS / VAR LOG ===');
    const p = await ssh.execCommand('du -sh /root/.pm2/logs /var/log/* 2>/dev/null | sort -hr | head -n 10');
    console.log(p.stdout);

    ssh.dispose();
  } catch (err) {
    console.error('Error:', err.message);
  } finally {
    process.exit(0);
  }
}

checkMore();
