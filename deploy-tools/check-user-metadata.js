const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  const res = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, email, role, metadata FROM users WHERE email IN (\'saifshah7865@gmail.com\', \'sufieditz@gmail.com\', \'dmarketer25@gmail.com\', \'zestdroidz@gmail.com\', \'sonathe333@gmail.com\', \'j09346412@gmail.com\');"');
  console.log(res.stdout);

  ssh.dispose();
}

run();
