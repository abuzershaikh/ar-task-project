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

    console.log('--- ALL 16 WORKERS REGISTERED ON OCT 4 ---');
    console.log(await runSql(`
      SELECT u.id, u.name, u.email, u.created_at,
             (SELECT COUNT(*) FROM task_assignments ta WHERE ta.worker_id = u.id OR ta.worker_id = u.email) as assignments,
             (SELECT COUNT(*) FROM task_submissions ts WHERE ts.worker_id = u.id OR ts.worker_id = u.email) as submissions
      FROM users u
      WHERE u.role = 'WORKER' AND DATE(u.created_at) = '2026-10-04'
      ORDER BY u.created_at DESC;
    `));

    console.log('--- ALL 24 WORKERS REGISTERED ON OCT 3 ---');
    console.log(await runSql(`
      SELECT u.id, u.name, u.email, u.created_at,
             (SELECT COUNT(*) FROM task_assignments ta WHERE ta.worker_id = u.id OR ta.worker_id = u.email) as assignments,
             (SELECT COUNT(*) FROM task_submissions ts WHERE ts.worker_id = u.id OR ts.worker_id = u.email) as submissions
      FROM users u
      WHERE u.role = 'WORKER' AND DATE(u.created_at) = '2026-10-03'
      ORDER BY u.created_at DESC;
    `));


    ssh.dispose();
  } catch (err) {
    console.error('Error:', err);
    ssh.dispose();
  }
})();
