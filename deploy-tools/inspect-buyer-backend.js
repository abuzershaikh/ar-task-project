const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function inspect() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== BUYER SUPPORT CONVERSATIONS COUNT & ROWS ===');
    const rows = await ssh.execCommand("mysql -u taskapp -p'taskapp_password' task_platform -e 'SELECT * FROM buyer_support_conversations;'");
    console.log(rows.stdout);

    console.log('=== TASK ENGINE PM2 STATUS & PROCESS PATH ===');
    const pm2Desc = await ssh.execCommand('pm2 jlist');
    const pm2List = JSON.parse(pm2Desc.stdout);
    for (const p of pm2List) {
      console.log(`- ${p.name}: status=${p.pm2_env.status}, cwd=${p.pm2_env.pm_cwd}, script=${p.pm2_env.pm_exec_path}`);
    }

  } catch (e) {
    console.error('Error:', e);
  } finally {
    ssh.dispose();
  }
}

inspect();
