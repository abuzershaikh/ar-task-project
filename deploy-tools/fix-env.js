const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function fixEnv() {
    await ssh.connect({
      host: '95.179.178.6',
      username: 'root',
      password: 'i_G72#y}(6gACDDU'
    });
    
    console.log("Updating .env...");
    await ssh.execCommand('sed -i "s/NODE_ENV=production/NODE_ENV=development/g" /var/www/task-engine/.env');
    
    console.log("Restarting PM2...");
    await ssh.execCommand('pm2 restart task-engine --update-env', { cwd: '/var/www/task-engine' });
    
    ssh.dispose();
}
fixEnv();
