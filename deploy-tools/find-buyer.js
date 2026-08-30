const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function showAllUsers() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    const res = await ssh.execCommand('mysql -e "SELECT id, email, role FROM task_platform.users LIMIT 10;"');
    console.log('Users in DB:\n', res.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

showAllUsers();
