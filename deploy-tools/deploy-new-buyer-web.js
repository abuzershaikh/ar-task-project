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

const WEB_BUILD_DIR = path.resolve(__dirname, '../buyer-web/build/web');
const ZIP_FILE = path.resolve(__dirname, 'buyer-web.zip');

async function exec(cmd) {
  console.log(`\n> ${cmd}`);
  const res = await ssh.execCommand(cmd);
  if (res.stdout) console.log(res.stdout);
  if (res.stderr) console.error('STDERR:', res.stderr);
  return res;
}

async function main() {
  if (!fs.existsSync(path.join(WEB_BUILD_DIR, 'index.html'))) {
    console.error('Error: buyer-web/build/web/index.html does not exist! Web build missing.');
    process.exit(1);
  }

  console.log('1. Packaging new buyer-web build into buyer-web.zip...');
  const zip = new AdmZip();
  zip.addLocalFolder(WEB_BUILD_DIR);
  zip.writeZip(ZIP_FILE);
  const sizeMb = (fs.statSync(ZIP_FILE).size / 1024 / 1024).toFixed(2);
  console.log(`buyer-web.zip created successfully (${sizeMb} MB)!`);

  console.log('\n2. Connecting to VPS (65.20.77.112)...');
  await ssh.connect(config);
  console.log('Connected to VPS!');

  // Create a backup of existing web files on VPS for safety
  console.log('\n3. Creating safety backup of current /var/www/buyer-web on VPS...');
  await exec('mkdir -p /var/www/backup_web && cp -r /var/www/buyer-web /var/www/backup_web/buyer-web-prev');

  console.log('\n4. Uploading new buyer-web.zip...');
  await ssh.putFile(ZIP_FILE, '/var/www/source.zip');
  console.log('Upload complete!');

  console.log('\n5. Extracting new web files into /var/www/buyer-web...');
  await exec('rm -rf /var/www/buyer-web/* && unzip -o /var/www/source.zip -d /var/www/buyer-web && rm -f /var/www/source.zip');
  await exec('chmod -R 755 /var/www/buyer-web && chown -R nginx:nginx /var/www/buyer-web || true');

  console.log('\n6. Testing and reloading Nginx...');
  await exec('nginx -t');
  await exec('systemctl reload nginx');

  console.log('\n7. Verifying live response...');
  const res3001 = await exec('curl -s -I http://127.0.0.1:3001 | head -n 8');
  console.log('Port 3001 response:\n', res3001.stdout);

  const resHttps = await exec('curl -s -I https://reviewsgateway.in | head -n 8');
  console.log('HTTPS reviewsgateway.in response:\n', resHttps.stdout);

  console.log('\n=== NEW BUYER WEB DEPLOYMENT SUCCESSFUL ===');
  ssh.dispose();
}

main().catch(err => {
  console.error('Deployment failed:', err);
  ssh.dispose();
  process.exit(1);
});
