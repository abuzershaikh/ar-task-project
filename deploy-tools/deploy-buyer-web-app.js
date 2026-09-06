const { NodeSSH } = require('node-ssh');
const path = require('path');
const fs = require('fs');
const ssh = new NodeSSH();

async function deploy() {
  const localBuildDir = path.resolve(__dirname, '../buyer-web-app/build/web');
  const remoteDir = '/var/www/buyer-web';

  console.log('Verifying local build dir:', localBuildDir);
  if (!fs.existsSync(localBuildDir) || !fs.existsSync(path.join(localBuildDir, 'index.html'))) {
    console.error('Build directory not ready yet!');
    process.exit(1);
  }

  try {
    console.log('Connecting to VPS (65.20.77.112)...');
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });
    console.log('Connected to VPS!');

    // 1. Pack files locally using tar or zip
    const tarFile = path.resolve(__dirname, 'web-build.tar.gz');
    console.log('Packaging build directory to tar.gz...');
    require('child_process').execSync(`tar -czf "${tarFile}" -C "${localBuildDir}" .`);
    console.log('Packaged successfully. Size:', fs.statSync(tarFile).size, 'bytes');

    // 2. Upload tar.gz to VPS
    console.log('Uploading tar.gz to VPS /tmp/web-build.tar.gz...');
    await ssh.putFile(tarFile, '/tmp/web-build.tar.gz');
    console.log('Uploaded successfully!');

    // 3. Extract to /var/www/buyer-web
    console.log('Extracting on VPS to', remoteDir);
    await ssh.execCommand(`mkdir -p ${remoteDir} && rm -rf ${remoteDir}/* && tar -xzf /tmp/web-build.tar.gz -C ${remoteDir} && rm -f /tmp/web-build.tar.gz`);
    await ssh.execCommand(`chown -R nginx:nginx ${remoteDir} || chown -R www-data:www-data ${remoteDir} || true`);
    await ssh.execCommand(`chmod -R 755 ${remoteDir}`);

    console.log('Testing Nginx configuration...');
    const testNginx = await ssh.execCommand('nginx -t');
    console.log(testNginx.stdout || testNginx.stderr);

    console.log('Reloading Nginx...');
    await ssh.execCommand('nginx -s reload');

    // 5. Test local curl
    console.log('Testing HTTP response on VPS...');
    const testRes = await ssh.execCommand('curl -sI http://127.0.0.1:3001');
    console.log('Port 3001 Response:\n', testRes.stdout);

    const testDomain = await ssh.execCommand('curl -sI -H "Host: reviewsgateway.in" http://127.0.0.1');
    console.log('Host reviewsgateway.in Response:\n', testDomain.stdout);

    // Clean up local tar
    if (fs.existsSync(tarFile)) fs.unlinkSync(tarFile);
    console.log('\n🎉 Deployment Complete!');
  } catch (err) {
    console.error('Deployment error:', err.message);
  } finally {
    ssh.dispose();
    process.exit(0);
  }
}

deploy();
