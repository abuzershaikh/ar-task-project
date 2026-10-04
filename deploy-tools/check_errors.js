const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

(async () => {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    const runSql = async (sql) => {
      await ssh.execCommand(`cat << 'EOF' > /tmp/query.sql\n${sql}\nEOF`);
      const res = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform < /tmp/query.sql');
      return res.stdout || res.stderr;
    };

    console.log('--- PM2 PROCESS LIST ---');
    const pms = await ssh.execCommand('pm2 list');
    console.log(pms.stdout);


    console.log('\n--- CHECK PM2 LOGS FOR task-engine-api ---');
    const logs = await ssh.execCommand('pm2 logs task-engine-api --lines 60 --nostream');
    console.log(logs.stdout);


    ssh.dispose();
  } catch (err) {
    console.error('Error:', err);
    ssh.dispose();
  }
})();
