const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function checkAllTables() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== SHOW TABLES IN task_platform ===');
    const tbls = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SHOW TABLES;"');
    console.log(tbls.stdout);

    console.log('=== CHECK WAPPBUZZ DATABASE TABLES ===');
    const wpTbls = await ssh.execCommand('mysql -u taskapp -ptaskapp_password wappbuzz -e "SHOW TABLES;"');
    console.log(wpTbls.stdout);

    console.log('=== CHECK ALL USERS WITH EMAIL OR ROLE LIKE BUYER ===');
    const bRes = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, email, full_name, role FROM users;"');
    console.log(bRes.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

checkAllTables();
