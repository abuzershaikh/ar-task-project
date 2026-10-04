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
      const b64 = Buffer.from(sql).toString('base64');
      const res = await ssh.execCommand(`echo "${b64}" | base64 -d | mysql -u taskapp -ptaskapp_password task_platform`);
      return res.stdout;
    };

    console.log('--- RECENT 20 USERS ---');
    console.log(await runSql('SELECT id, name, email, created_at, role, status FROM users ORDER BY created_at DESC LIMIT 20;'));

    ssh.dispose();
  } catch (err) {
    console.error('Error:', err);
    ssh.dispose();
  }
})();
