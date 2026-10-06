const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function main() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  const res = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "
    SELECT id, email, full_name, role FROM users WHERE email IN (
      'rohitxxxd45@gmail.com',
      'amarjeet76366@gmail.com',
      'iammajibur777@gmail.com',
      'kumbhakarsadhu8967@gmail.com',
      'valvishivdas324@gmail.com',
      'singhroshan3103@gmail.com',
      'dy4196981@gmail.com',
      'debendra9096@gmail.com',
      'souradeepghosh526@gmail.com',
      'shaikyaseen56721@gmail.com',
      'chowdryprmeet01@gmail.com',
      'musicclouds123@gmail.com',
      'protim621@gmail.com'
    );
  "`);
  console.log('USERS FOUND IN MYSQL:\n', res.stdout);

  ssh.dispose();
}

main().catch(console.error);
