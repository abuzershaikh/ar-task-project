const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function checkSpUsers() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== SP_USERS IN WAPPBUZZ ===');
    const res = await ssh.execCommand('mysql wappbuzz -e "SELECT id, email, fullname, role, status FROM sp_users;"');
    console.log(res.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

checkSpUsers();
