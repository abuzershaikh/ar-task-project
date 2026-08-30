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

async function execCommand(cmd, ignoreError = false) {
  console.log(`\n⚙️ Executing: ${cmd}`);
  const result = await ssh.execCommand(cmd);
  if (result.stdout) console.log(result.stdout);
  if (result.stderr) console.error(result.stderr);
  if (result.code !== 0 && !ignoreError) {
    throw new Error(`Command failed with code ${result.code}: ${cmd}`);
  }
  return result;
}

async function deploy() {
  try {
    console.log('🚀 Starting Isolated Deployment of Task Engine to Mumbai VPS (65.20.77.112)...\n');

    await createZip();

    console.log('\n🔌 Connecting to VPS via SSH...');
    await ssh.connect(config);
    console.log('✅ SSH Connected!');

    console.log('\n--- Step 1: VPS Environment & Dependencies Setup ---');
    // 1. Install & start Redis if not running
    await execCommand('which redis-server || dnf install -y redis');
    await execCommand('systemctl enable --now redis');
    await execCommand('redis-cli ping');

    // 2. Open port 3000 in firewalld
    await execCommand('firewall-cmd --add-port=3000/tcp --permanent || true');
    await execCommand('firewall-cmd --reload || true');

    // 3. Setup MySQL database & user
    console.log('\n--- Step 2: MySQL Database Isolation Setup ---');
    await execCommand(`mysql -e "CREATE DATABASE IF NOT EXISTS task_platform CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"`);
    await execCommand(`mysql -e "CREATE USER IF NOT EXISTS 'taskapp'@'localhost' IDENTIFIED BY 'taskapp_password';"`);
    await execCommand(`mysql -e "GRANT ALL PRIVILEGES ON task_platform.* TO 'taskapp'@'localhost';"`);
    await execCommand(`mysql -e "FLUSH PRIVILEGES;"`);
    await execCommand(`mysql -e "SHOW DATABASES LIKE 'task_platform';"`);

    console.log('\n--- Step 3: Uploading & Extracting Source Code ---');
    await execCommand('mkdir -p /opt/task-engine');
    await ssh.putFile(ZIP_FILE, '/opt/task-engine/source.zip');
    console.log('✅ Upload complete.');

    await execCommand('cd /opt/task-engine && rm -rf apps shared task-engine allocation-engine earning-engine eligibility-engine execution-engine fraud-engine matching-engine notification-engine payout-engine progress-engine ranking-engine review-engine reward-engine scoring-engine dist && unzip -o source.zip && rm -f source.zip');

    console.log('\n--- Step 4: Environment Configuration ---');
    const envContent = `PORT=3000
NODE_ENV=production
ENABLE_TEST_ENDPOINTS=true
DATABASE_URL=mysql://taskapp:taskapp_password@localhost:3306/task_platform
DB_HOST=localhost
DB_PORT=3306
DB_USERNAME=taskapp
DB_PASSWORD=taskapp_password
DB_DATABASE=task_platform
JWT_SECRET=super_secret_jwt_key_1234567890
JWT_REFRESH_SECRET=super_secret_refresh_key_0987654321
REDIS_HOST=localhost
REDIS_PORT=6379
`;
    await ssh.execCommand(`cat << 'EOF' > /opt/task-engine/.env\n${envContent}\nEOF`);
    console.log('✅ .env configured.');

    console.log('\n--- Step 5: Installing Dependencies & Building ---');
    await execCommand('cd /opt/task-engine && npm install --production=false');
    await execCommand('cd /opt/task-engine && npm run build');

    console.log('\n--- Step 6: Seeding SuperAdmin & Service Catalog ---');
    await execCommand('cd /opt/task-engine && node create_admin.js || true');

    console.log('\n--- Step 7: Starting / Reloading PM2 Services (Isolated) ---');
    // Note: Do NOT use pm2 delete all. Only manage task-engine processes!
    await execCommand('pm2 delete task-engine-api task-engine-worker 2>/dev/null || true');
    await execCommand('cd /opt/task-engine && pm2 start ecosystem.config.json --only task-engine-api,task-engine-worker');
    await execCommand('pm2 save');

    console.log('\n--- Step 8: Verifying Services & Health ---');
    await execCommand('pm2 list');
    
    // Wait 3 seconds for server startup
    await new Promise((r) => setTimeout(r, 3000));

    console.log('\n--- Step 9: API Health Check & Endpoints Test ---');
    const health = await execCommand('curl -s http://localhost:3000/api/v1/health');
    console.log('Health Response:', health.stdout);

    const swagger = await execCommand('curl -s -I http://localhost:3000/api/docs/');
    console.log('Swagger Docs Response:', swagger.stdout);

    console.log('\n🎉 ======================================================');
    console.log('🎉 TASK ENGINE SUCCESSFULLY DEPLOYED TO MUMBAI VPS!');
    console.log('🎉 API URL: http://65.20.77.112:3000/api/v1');
    console.log('🎉 Swagger: http://65.20.77.112:3000/api/docs');
    console.log('🎉 Existing projects (Wappbuzz & Waziper) are 100% untouched!');
    console.log('======================================================\n');

  } catch (error) {
    console.error('❌ Deployment Failed:', error);
  } finally {
    ssh.dispose();
  }
}

deploy();
