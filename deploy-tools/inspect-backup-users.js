const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function inspectBackup() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('--- USERS IN BACKUP BEFORE WIPE ---');
    const bUsers = await ssh.execCommand('grep -E "INSERT INTO \`users\`" /root/task_platform_backup_before_wipe.sql | head -n 30');
    console.log(bUsers.stdout);

    console.log('--- WORKERS IN BACKUP BEFORE WIPE ---');
    const bWorkers = await ssh.execCommand('grep -E "INSERT INTO \`workers\`" /root/task_platform_backup_before_wipe.sql | head -n 30');
    console.log(bWorkers.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

inspectBackup();
