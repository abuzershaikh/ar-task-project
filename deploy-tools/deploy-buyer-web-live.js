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

const WEB_DIR = path.resolve(__dirname, '../buyer-web');
const ZIP_PATH = path.resolve(__dirname, 'web-update.zip');

async function main() {
  console.log('1. Packing HTML & assets (excluding large APK)...');
  const zip = new AdmZip();

  // Add all HTML files
  const files = ['index.html', 'about.html', 'terms.html', 'privacy.html', 'contact.html'];
  for (const f of files) {
    const fullPath = path.join(WEB_DIR, f);
    if (fs.existsSync(fullPath)) {
      zip.addLocalFile(fullPath);
      console.log(` Added ${f}`);
    } else {
      console.warn(` Warning: ${f} not found!`);
    }
  }

  // Add assets folder
  const assetsDir = path.join(WEB_DIR, 'assets');
  if (fs.existsSync(assetsDir)) {
    zip.addLocalFolder(assetsDir, 'assets');
    console.log(' Added assets/');
  }

  zip.writeZip(ZIP_PATH);
  const sizeKb = (fs.statSync(ZIP_PATH).size / 1024).toFixed(1);
  console.log(`Created web-update.zip (${sizeKb} KB)`);

  console.log('\n2. Connecting to VPS (65.20.77.112)...');
  await ssh.connect(config);
  console.log('Connected!');

  console.log('\n3. Uploading web-update.zip to VPS...');
  await ssh.putFile(ZIP_PATH, '/var/www/buyer-web/web-update.zip');
  console.log('Uploaded successfully!');

  console.log('\n4. Extracting files in /var/www/buyer-web...');
  const extractCmd = 'cd /var/www/buyer-web && unzip -o web-update.zip && rm -f web-update.zip Buyer_App_Release.apk && chown -R nginx:nginx /var/www/buyer-web && chmod -R 755 /var/www/buyer-web';
  const extractRes = await ssh.execCommand(extractCmd);
  console.log(extractRes.stdout);
  if (extractRes.stderr) console.error('STDERR:', extractRes.stderr);

  console.log('\n5. Reloading Nginx...');
  await ssh.execCommand('nginx -t');
  await ssh.execCommand('systemctl reload nginx');

  console.log('\n6. Checking updated files on VPS:');
  const ls = await ssh.execCommand('ls -la /var/www/buyer-web');
  console.log(ls.stdout);

  console.log('\n7. Verifying HTTP/HTTPS responses...');
  const resHome = await ssh.execCommand('curl -sI https://www.reviewsgateway.in/ | head -n 5');
  console.log('Home HTTPS:\n', resHome.stdout);

  const resTerms = await ssh.execCommand('curl -sI https://www.reviewsgateway.in/terms.html | head -n 5');
  console.log('Terms HTTPS:\n', resTerms.stdout);

  const resAbout = await ssh.execCommand('curl -sI https://www.reviewsgateway.in/about.html | head -n 5');
  console.log('About HTTPS:\n', resAbout.stdout);

  console.log('\n=== DEPLOYMENT COMPLETED SUCCESSFULLY ===');
  ssh.dispose();
  fs.unlinkSync(ZIP_PATH);
}

main().catch(err => {
  console.error('Deployment error:', err);
  ssh.dispose();
  if (fs.existsSync(ZIP_PATH)) fs.unlinkSync(ZIP_PATH);
  process.exit(1);
});
