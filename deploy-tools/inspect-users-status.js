const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function main() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
    const q1 = "SELECT role, status, count(*) as count FROM users GROUP BY role, status;";
    const res1 = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "${q1}"`);
    console.log('USER STATUS GROUP BY:');
    console.log(res1.stdout);

    const q2 = "DESCRIBE users;";
    const res2 = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "${q2}"`);
    console.log('USERS TABLE COLS:');
    console.log(res2.stdout);

    const q3 = "SELECT u.id, u.email, u.role, u.status, u.created_at, u.last_login FROM users u LIMIT 10;";
    const res3 = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "${q3}"`);
    console.log('SAMPLE USERS:');
    console.log(res3.stdout);
  } catch (e) {
    console.error(e);
  } finally {
    ssh.dispose();
  }
}

main();
