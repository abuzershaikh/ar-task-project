const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
    const vpsDate = await ssh.execCommand('date && date -u');
    console.log('VPS DATE:\n', vpsDate.stdout);

    const findRes = await ssh.execCommand('find /opt/task-engine/dist -name "*task.entity*"');
    console.log('TASK ENTITY PATHS:\n', findRes.stdout);

    const testDates = await ssh.execCommand(`node -e "
      const mysql = require('/opt/task-engine/node_modules/mysql2/promise');
      async function main() {
        const conn = await mysql.createConnection({
          host: '127.0.0.1',
          user: 'taskapp',
          password: 'taskapp_password',
          database: 'task_platform'
        });
        const [rows] = await conn.query('SELECT id, status, deadline, assigned_at, accepted_at FROM tasks WHERE deadline IS NOT NULL ORDER BY updated_at DESC LIMIT 5');
        const now = new Date();
        console.log('Node now (ISO):', now.toISOString());
        console.log('Node now (getTime):', now.getTime());
        for (const r of rows) {
          console.log('--- Task:', r.id, 'Status:', r.status);
          console.log('  raw deadline:', r.deadline);
          console.log('  typeof deadline:', typeof r.deadline);
          if (r.deadline instanceof Date) {
            console.log('  ISO:', r.deadline.toISOString());
            console.log('  getTime():', r.deadline.getTime());
            console.log('  diff minutes (deadline - now):', Math.round((r.deadline.getTime() - now.getTime()) / 60000));
            console.log('  is passed?', r.deadline < now);
          }
        }
        await conn.end();
      }
      main();
    "`);
    console.log('DATES:\n', testDates.stdout);
    if (testDates.stderr) console.log('STDERR:\n', testDates.stderr);
  } catch (e) {
    console.error(e);
  } finally {
    ssh.dispose();
  }
}
run();
