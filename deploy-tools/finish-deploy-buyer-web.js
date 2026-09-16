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

const WEB_BUILD_DIR = path.resolve(__dirname, '../buyer-web-app/build/web');
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
    console.error('Error: build/web/index.html does not exist yet! Build might still be running or failed.');
    process.exit(1);
  }

  console.log('Packaging build/web into buyer-web.zip...');
  const zip = new AdmZip();
  zip.addLocalFolder(WEB_BUILD_DIR);
  zip.writeZip(ZIP_FILE);
  console.log(`buyer-web.zip created (${(fs.statSync(ZIP_FILE).size / 1024 / 1024).toFixed(2)} MB)!`);

  console.log('\nConnecting to VPS (65.20.77.112)...');
  await ssh.connect(config);
  console.log('Connected!');

  console.log('\nUploading buyer-web.zip to /var/www/buyer-web/source.zip...');
  await ssh.putFile(ZIP_FILE, '/var/www/buyer-web/source.zip');
  console.log('Uploaded successfully!');

  console.log('\nExtracting web bundle on VPS...');
  await exec('cd /var/www/buyer-web && unzip -o source.zip && rm -f source.zip');
  await exec('chmod -R 755 /var/www/buyer-web');

  console.log('\nTesting and reloading Nginx...');
  await exec('nginx -t');
  await exec('systemctl reload nginx');

  console.log('\nVerifying live web response on port 3001...');
  const testCurl = await exec('curl -s -I http://127.0.0.1:3001 | head -n 5');
  console.log('Test Curl Response:\n', testCurl.stdout);

  console.log('\n=== BUYER WEB DEPLOYMENT COMPLETE ===');
  ssh.dispose();
}

main().catch(err => {
  console.error('Deployment error:', err);
  ssh.dispose();
  process.exit(1);
});
