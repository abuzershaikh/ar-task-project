const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function main() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  const res1 = await ssh.execCommand("mysql -u taskapp -ptaskapp_password task_platform -e 'SHOW TABLES LIKE \"%setting%\";'");
  console.log('Tables:', res1.stdout);

  const res2 = await ssh.execCommand("mysql -u taskapp -ptaskapp_password task_platform -e 'SELECT * FROM system_settings LIMIT 20;'");
  console.log('System settings rows:', res2.stdout);

  ssh.dispose();
}

main().catch(console.error);
