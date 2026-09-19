const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  console.log('=== WORKERS MATCHING FIREBASE UIDS ===');
  const w = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, user_id, status, fcm_token IS NOT NULL as has_fcm, substring(fcm_token, 1, 30) as fcm_snip, last_active_at FROM workers WHERE user_id IN (\'6Fl6De9q19XdT6jnC5TSGYAx8NG3\', \'kQzd3bZD7pgA908xGE6NoGogetB3\', \'NPzSZu9cSBgYUb1WXalcylMgjoF3\', \'Z1kC3TPyeSZopLJZk0kkSRvWOHq1\', \'MYDovhuR8zcbLlvazaAG8qdWLXr1\');"');
  console.log(w.stdout);

  console.log('=== ALL WORKERS WITH NON-NULL USER_ID ===');
  const allw = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, user_id, status, last_active_at FROM workers;"');
  console.log(allw.stdout);

  ssh.dispose();
}

run();
