const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function fixSyncRaceCondition() {
    await ssh.connect({
      host: '95.179.178.6',
      username: 'root',
      password: 'i_G72#y}(6gACDDU'
    });
    
    console.log("Dropping and recreating database...");
    await ssh.execCommand('mysql -u root -e "DROP DATABASE IF EXISTS task_platform; CREATE DATABASE task_platform;"');
    
    console.log("Starting a SINGLE instance to allow safe synchronization...");
    await ssh.execCommand('pm2 delete task-engine', { cwd: '/var/www/task-engine' });
    await ssh.execCommand('pm2 start dist/main.js --name task-engine -i 1', { cwd: '/var/www/task-engine' });
    
    ssh.dispose();
}
fixSyncRaceCondition();
