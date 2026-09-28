const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== CHECK IOREDIS ON VPS ===');
    const res = await ssh.execCommand('cd /opt/task-engine && node -e "const Redis = require(\'ioredis\'); const r = new Redis(); r.ping().then(p => { console.log(\'Redis ping:\', p); process.exit(0); }).catch(e => { console.error(e); process.exit(1); });"');
    console.log(res.stdout || res.stderr);

  } catch (e) {
    console.error('Error:', e.message);
  } finally {
    ssh.dispose();
    process.exit(0);
  }
}

run();
