const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('--- NGINX DOMAINS ---');
    const nginx = await ssh.execCommand('grep -E "server_name|proxy_pass" /etc/nginx/conf.d/*.conf /etc/nginx/sites-enabled/* 2>/dev/null');
    console.log(nginx.stdout || nginx.stderr);

    console.log('\n--- EXTERNAL CURL TEST ---');
    // Test curl from external or public
    const curlExternal = await ssh.execCommand('curl -i -s -k https://api.taskapp.in/api/v1/health || curl -i -s -k https://taskapp.in/api/v1/health');
    console.log(curlExternal.stdout || curlExternal.stderr);

  } catch (e) {
    console.error('Error:', e.message);
  } finally {
    ssh.dispose();
    process.exit(0);
  }
}

run();
