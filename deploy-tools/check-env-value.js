const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function checkEnvValue() {
    await ssh.connect({
      host: '95.179.178.6',
      username: 'root',
      password: 'i_G72#y}(6gACDDU'
    });
    const result = await ssh.execCommand('node -e "require(\'dotenv\').config(); console.log(\'DB_USER:\', process.env.DB_USERNAME)"', { cwd: '/var/www/task-engine' });
    console.log("DB_USER from dotenv:", result.stdout);
    
    // Also let's just update the pm2 to pass env explicitly as a fallback
    await ssh.execCommand('pm2 delete task-engine');
    await ssh.execCommand('pm2 start dist/main.js --name task-engine -i 2 --env production', { cwd: '/var/www/task-engine' });
    
    ssh.dispose();
}
checkEnvValue();
