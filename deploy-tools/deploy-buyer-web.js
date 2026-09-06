const { NodeSSH } = require('node-ssh');
const path = require('path');
const fs = require('fs');

const ssh = new NodeSSH();

const config = {
  host: '65.20.77.112',
  username: 'root',
  password: 'G8u$RW{5m46buXgw',
  readyTimeout: 60000,
};

const ZIP_FILE = path.resolve(__dirname, 'buyer-web.zip');

async function exec(cmd) {
  console.log(`\n> ${cmd}`);
  const res = await ssh.execCommand(cmd);
  if (res.stdout) console.log(res.stdout);
  if (res.stderr) console.error('STDERR:', res.stderr);
  return res;
}

async function deployBuyerWeb() {
  try {
    console.log('Connecting to VPS (65.20.77.112)...');
    await ssh.connect(config);
    console.log('Connected!');

    // 1. Create separate directory /var/www/buyer-web
    console.log('\nCreating directory /var/www/buyer-web...');
    await exec('mkdir -p /var/www/buyer-web');

    // 2. Upload zip
    console.log('\nUploading buyer-web.zip (16 MB)...');
    await ssh.putFile(ZIP_FILE, '/var/www/buyer-web/source.zip');
    console.log('Uploaded successfully!');

    // 3. Extract in separate directory
    console.log('\nExtracting web bundle...');
    await exec('cd /var/www/buyer-web && unzip -o source.zip && rm -f source.zip');
    await exec('chmod -R 755 /var/www/buyer-web');

    // 4. Configure Nginx for swiftcommerce.in and port 3001 preview
    console.log('\nConfiguring Nginx for swiftcommerce.in...');
    const nginxConf = `
server {
    listen 80;
    server_name swiftcommerce.in www.swiftcommerce.in;

    root /var/www/buyer-web;
    index index.html;

    client_max_body_size 50M;

    gzip on;
    gzip_types text/plain text/css application/javascript application/json image/svg+xml;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api/v1/ {
        proxy_pass http://127.0.0.1:3000/api/v1/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 60;
    }
}

server {
    listen 3001;
    server_name _;

    root /var/www/buyer-web;
    index index.html;

    client_max_body_size 50M;

    gzip on;
    gzip_types text/plain text/css application/javascript application/json image/svg+xml;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api/v1/ {
        proxy_pass http://127.0.0.1:3000/api/v1/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 60;
    }
}
`;

    const tmpConf = path.resolve(__dirname, 'swiftcommerce.conf');
    fs.writeFileSync(tmpConf, nginxConf.trim());
    await ssh.putFile(tmpConf, '/etc/nginx/conf.d/swiftcommerce.conf');
    fs.unlinkSync(tmpConf);

    // 5. Test & reload Nginx
    console.log('\nTesting Nginx configuration...');
    const tRes = await exec('nginx -t');
    if (tRes.code === 0) {
      console.log('\nReloading Nginx...');
      await exec('systemctl reload nginx');
      console.log('Nginx reloaded successfully!');
    } else {
      throw new Error('Nginx configuration test failed!');
    }

    // 6. Test curl on port 3001
    console.log('\nVerifying live web response...');
    const testCurl = await exec('curl -s -I http://127.0.0.1:3001 | head -n 5');
    console.log('Test Curl Response:\n', testCurl.stdout);

    console.log('\n=== DEPLOYMENT COMPLETED SUCCESSFULLY ===');
    console.log('1. Live on Domain: http://swiftcommerce.in (once DNS points to 65.20.77.112)');
    console.log('2. Live on IP Preview: http://65.20.77.112:3001');

  } catch (err) {
    console.error('Deployment Error:', err);
  } finally {
    ssh.dispose();
    process.exit(0);
  }
}

deployBuyerWeb();
