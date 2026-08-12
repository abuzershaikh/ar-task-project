const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function rewriteEnv() {
    await ssh.connect({
      host: '95.179.178.6',
      username: 'root',
      password: 'i_G72#y}(6gACDDU'
    });
    
    console.log('Rewriting .env...');
    const envFix = `PORT=3000
NODE_ENV=production
DATABASE_URL=mysql://taskapp:taskapp_password@localhost:3306/task_platform
JWT_SECRET=super_secret_jwt_key_1234567890
REDIS_HOST=localhost
REDIS_PORT=6379
JWT_REFRESH_SECRET=super_secret_refresh_key_1234567890
DB_DATABASE=task_platform
DB_HOST=localhost
DB_PORT=3306
DB_USERNAME=taskapp
DB_PASSWORD=taskapp_password
`;
    // We use a base64 encode/decode trick to write multiline text safely
    const b64 = Buffer.from(envFix).toString('base64');
    await ssh.execCommand(`echo "${b64}" | base64 -d > /var/www/task-engine/.env`);
    
    console.log("Restarting PM2 with update-env");
    await ssh.execCommand('pm2 restart task-engine --update-env');
    
    ssh.dispose();
}
rewriteEnv();
