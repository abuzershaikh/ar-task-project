const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function checkFirebaseUsers() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    const res = await ssh.execCommand('NODE_PATH=/opt/task-engine/node_modules node /root/check_firebase.js');
    console.log(res.stdout);
    if (res.stderr) console.error(res.stderr);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

checkFirebaseUsers();
