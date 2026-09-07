const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function showAllUsers() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
      readyTimeout: 60000,
    });

    const res = await ssh.execCommand('mysql -e "SELECT id, email, role FROM task_platform.users WHERE email LIKE \'%sonathe%\';"');
    console.log('Users in DB:\n', res.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

showAllUsers();
