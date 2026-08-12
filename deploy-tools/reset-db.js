const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function resetDb() {
    await ssh.connect({
      host: '95.179.178.6',
      username: 'root',
      password: 'i_G72#y}(6gACDDU'
    });
    
    console.log("Dropping and recreating database...");
    await ssh.execCommand('mysql -u root -e "DROP DATABASE IF EXISTS task_platform; CREATE DATABASE task_platform;"');
    
    console.log("Restarting PM2 to trigger clean sync...");
    await ssh.execCommand('pm2 restart task-engine', { cwd: '/var/www/task-engine' });
    
    ssh.dispose();
}
resetDb();
