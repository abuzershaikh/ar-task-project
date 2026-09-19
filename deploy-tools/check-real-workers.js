const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  const r1 = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, email, role FROM users WHERE email LIKE \'%sufi%\' OR email LIKE \'%saif%\' OR email LIKE \'%dmarketer%\' OR email LIKE \'%zest%\' OR email LIKE \'%sona%\' OR email LIKE \'%j093%\';"');
  console.log('=== USERS ===\n', r1.stdout);

  const r2 = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, user_id, status, last_active_at FROM workers WHERE user_id IN (\'kQzd3bZD7pgA908xGE6NoGogetB3\', \'6Fl6De9q19XdT6jnC5TSGYAx8NG3\', \'NPzSZu9cSBgYUb1WXalcylMgjoF3\', \'Z1kC3TPyeSZopLJZk0kkSRvWOHq1\', \'MYDovhuR8zcbLlvazaAG8qdWLXr1\');"');
  console.log('=== WORKERS ===\n', r2.stdout);

  const r3 = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "DESCRIBE workers;"');
  console.log('=== WORKERS SCHEMA ===\n', r3.stdout);

  ssh.dispose();
}

run();
