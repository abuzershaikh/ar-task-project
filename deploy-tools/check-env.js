const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function checkEnv() {
    await ssh.connect({
      host: '95.179.178.6',
      username: 'root',
      password: 'i_G72#y}(6gACDDU'
    });
    
    // Check .env
    const envFile = await ssh.execCommand('cat /var/www/task-engine/.env');
    console.log("ENV FILE:");
    console.log(envFile.stdout);
    
    console.log("Restarting PM2 with update-env");
    await ssh.execCommand('pm2 restart task-engine --update-env');
    
    ssh.dispose();
}
checkEnv();
