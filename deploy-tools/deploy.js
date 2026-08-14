const { NodeSSH } = require('node-ssh');
const AdmZip = require('adm-zip');
const fs = require('fs');
const path = require('path');

const ssh = new NodeSSH();

const config = {
  host: '95.179.178.6',
  username: 'root',
  password: 'i_G72#y}(6gACDDU',
  readyTimeout: 60000,
};

const SRC_DIR = path.resolve(__dirname, '../Task engine');
const ZIP_FILE = path.resolve(__dirname, 'task-engine.zip');

async function createZip() {
  console.log('Creating ZIP archive...');
  const zip = new AdmZip();
  zip.addLocalFolder(SRC_DIR, '', (filename) => {
    return !filename.includes('node_modules') && !filename.includes('dist') && !filename.includes('.git') && !filename.endsWith('.env');
  });
  zip.writeZip(ZIP_FILE);
  console.log('ZIP archive created!');
}

async function execCommand(cmd) {
  console.log(`Executing: ${cmd}`);
  const result = await ssh.execCommand(cmd);
  if (result.stdout) console.log(result.stdout);
  if (result.stderr) console.error(result.stderr);
  if (result.code !== 0) throw new Error(`Command failed: ${cmd}`);
}

async function deploy() {
  try {
    await createZip();
    console.log('Connecting to server...');
    
    await ssh.connect(config);
    console.log('Connected!');

    console.log('Updating system...');
    await execCommand('apt-get update && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y');
    console.log('Installing dependencies...');
    await execCommand('DEBIAN_FRONTEND=noninteractive apt-get install -y curl unzip redis-server mysql-server');
    
    console.log('Installing Node.js...');
    await execCommand('curl -fsSL https://deb.nodesource.com/setup_20.x | bash -');
    await execCommand('DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs');
    await execCommand('npm install -g pm2');

    console.log('Setting up database...');
    await execCommand(`mysql -e "CREATE DATABASE IF NOT EXISTS task_platform CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"`);
    await execCommand(`mysql -e "CREATE USER IF NOT EXISTS 'taskapp'@'localhost' IDENTIFIED BY 'taskapp_password';"`);
    await execCommand(`mysql -e "GRANT ALL PRIVILEGES ON task_platform.* TO 'taskapp'@'localhost';"`);
    await execCommand(`mysql -e "FLUSH PRIVILEGES;"`);

    console.log('Uploading code...');
    await execCommand('mkdir -p /var/www/task-engine');
    await ssh.putFile(ZIP_FILE, '/var/www/task-engine/source.zip');
    
    console.log('Extracting code...');
    await execCommand('cd /var/www/task-engine && unzip -o source.zip && rm source.zip');

    console.log('Setting up environment...');
    const envContent = `
PORT=3000
NODE_ENV=production
DATABASE_URL=mysql://taskapp:taskapp_password@localhost:3306/task_platform
JWT_SECRET=super_secret_jwt_key_1234567890
REDIS_HOST=localhost
REDIS_PORT=6379
`;
    await execCommand(`echo "${envContent.replace(/\\n/g, '\\\\n').replace(/\n/g, '\\n')}" > /var/www/task-engine/.env`);

    console.log('Installing project dependencies & building...');
    await execCommand('cd /var/www/task-engine && npm install');
    await execCommand('cd /var/www/task-engine && npm run build');

    console.log('Starting PM2...');
    const pm2Status = await ssh.execCommand('pm2 id task-engine');
    if (pm2Status.stdout.trim() === '[]') {
       await execCommand('cd /var/www/task-engine && pm2 start dist/main.js --name task-engine -i 2');
    } else {
       await execCommand('cd /var/www/task-engine && pm2 restart task-engine');
    }
    await execCommand('pm2 save');
    
    console.log('DEPLOYMENT SUCCESSFUL!');
  } catch (error) {
    console.error('Deployment Failed:', error);
  } finally {
    ssh.dispose();
  }
}

deploy();
