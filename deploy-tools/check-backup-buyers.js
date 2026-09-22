const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function checkBackupBuyers() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('--- FINDING BUYERS IN BACKUP FILE ---');
    const bRes = await ssh.execCommand('grep -i "BUYER" /root/task_platform_backup_before_wipe.sql | head -n 30');
    console.log(bRes.stdout);

    console.log('--- FINDING ALL USERS IN BACKUP FILE ---');
    const uRes = await ssh.execCommand('grep -E "INSERT INTO \`users\`" /root/task_platform_backup_before_wipe.sql');
    console.log(uRes.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

checkBackupBuyers();
