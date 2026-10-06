const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function check() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
    const logs = await ssh.execCommand('pm2 logs support-chat-engine --lines 30 --nostream');
    console.log('--- PM2 LOGS ---');
    console.log(logs.stdout || logs.stderr);

    const health = await ssh.execCommand('curl -s http://127.0.0.1:3005/health');
    console.log('--- HEALTH ---');
    console.log(health.stdout);

    const tables = await ssh.execCommand("mysql -u taskapp -ptaskapp_password task_platform -e 'SHOW TABLES LIKE \"%buyer_support%\";'");
    console.log('--- BUYER TABLES ---');
    console.log(tables.stdout);

    ssh.dispose();
  } catch (err) {
    console.error(err);
    ssh.dispose();
  }
}

check();
