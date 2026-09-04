const { NodeSSH } = require('node-ssh');
const AdmZip = require('adm-zip');
const path = require('path');
const fs = require('fs');

const ssh = new NodeSSH();

const config = {
  host: '65.20.77.112',
  username: 'root',
  password: 'G8u$RW{5m46buXgw',
  readyTimeout: 60000,
};

const SRC_DIR = path.resolve(__dirname, '../Task engine');
const ZIP_FILE = path.resolve(__dirname, 'task-engine-mumbai.zip');

async function createZip() {
  console.log('📦 Creating ZIP archive of Task engine...');
  const zip = new AdmZip();
  zip.addLocalFolder(SRC_DIR, '', (filename) => {
    return !filename.includes('node_modules') &&
           !filename.includes('dist') &&
           !filename.includes('.git') &&
           !filename.endsWith('.env');
  });
  zip.writeZip(ZIP_FILE);
  const stats = fs.statSync(ZIP_FILE);
  console.log(`✅ ZIP archive created: ${(stats.size / 1024 / 1024).toFixed(2)} MB`);
}

async function deploy() {
  try {
    await createZip();
    console.log('Connecting SSH...');
    await ssh.connect(config);
    console.log('Uploading zip...');
    await ssh.putFile(ZIP_FILE, '/opt/task-engine/source.zip');
    console.log('Unzipping...');
    await ssh.execCommand('cd /opt/task-engine && unzip -o source.zip && rm -f source.zip');
    console.log('Building NestJS backend...');
    const build = await ssh.execCommand('cd /opt/task-engine && npm run build');
    console.log('Build output:\n', build.stdout);
    if (build.stderr) console.error('Build errors:\n', build.stderr);
    
    console.log('Restarting PM2 api...');
    const restart = await ssh.execCommand('pm2 restart task-engine-api');
    console.log('Restart output:\n', restart.stdout);

    const status = await ssh.execCommand('pm2 status');
    console.log('Status:\n', status.stdout);
  } catch (err) {
    console.error('Deployment error:', err);
  } finally {
    process.exit(0);
  }
}

deploy();
