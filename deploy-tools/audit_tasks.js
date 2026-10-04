const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

(async () => {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('Connected to VPS.');

    const runSql = async (sql) => {
      const escaped = sql.replace(/"/g, '\\"');
      const res = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "${escaped}"`);
      return res.stdout;
    };

    console.log('--- SHOW TABLES ---');
    console.log(await runSql('SHOW TABLES;'));

    console.log('--- DESCRIBE task_assignments ---');
    console.log(await runSql('DESCRIBE task_assignments;'));

    console.log('--- task_assignments COUNT & RECENT ---');
    console.log(await runSql('SELECT COUNT(*) FROM task_assignments;'));
    console.log(await runSql('SELECT * FROM task_assignments ORDER BY id DESC LIMIT 10;'));

    console.log('--- DESCRIBE task_submissions ---');
    console.log(await runSql('DESCRIBE task_submissions;'));

    console.log('--- task_submissions COUNT & RECENT ---');
    console.log(await runSql('SELECT COUNT(*) FROM task_submissions;'));
    console.log(await runSql('SELECT id, task_id, worker_id, status, created_at FROM task_submissions ORDER BY created_at DESC LIMIT 10;'));

    console.log('--- TOTAL USERS COUNT ---');
    console.log(await runSql('SELECT COUNT(*) FROM users;'));
    console.log(await runSql('SELECT role, status, COUNT(*) FROM users GROUP BY role, status;'));

    console.log('--- TOTAL WORKERS IN workers TABLE ---');
    console.log(await runSql('SELECT COUNT(*) FROM workers;'));
    console.log(await runSql('SELECT status, kyc_status, COUNT(*) FROM workers GROUP BY status, kyc_status;'));



    ssh.dispose();
  } catch (err) {
    console.error('Error:', err);
    ssh.dispose();
  }
})();
