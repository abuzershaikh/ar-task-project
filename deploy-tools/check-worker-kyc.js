const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    const nodeScript = `
      const mysql = require('/opt/task-engine/node_modules/mysql2/promise');
      async function main() {
        const conn = await mysql.createConnection({
          host: '127.0.0.1',
          user: 'taskapp',
          password: 'taskapp_password',
          database: 'task_platform'
        });
        const [kyc] = await conn.query('SELECT * FROM kyc_profiles');
        console.log('KYC:', JSON.stringify(kyc, null, 2));
        const [workers] = await conn.query('SELECT id, userId, kycStatus, profile FROM workers WHERE id = ?', ['52695909-751a-48ef-b8b4-3e77e1d8558e']);
        console.log('WORKER:', JSON.stringify(workers, null, 2));
        if (workers.length > 0) {
          const [users] = await conn.query('SELECT id, email, fullName, phone FROM users WHERE id = ?', [workers[0].userId]);
          console.log('USER:', JSON.stringify(users, null, 2));
        }
        await conn.end();
      }
      main().catch(console.error);
    `;
    const res = await ssh.execCommand(`node -e "${nodeScript.replace(/\n/g, ' ')}"`);
    console.log(res.stdout || res.stderr);

  } catch (err) {
    console.error('Error:', err);
  } finally {
    ssh.dispose();
  }
}
run();
