const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  console.log('--- 1. Searching for "Taskearn" across VPS ---');
  const res1 = await ssh.execCommand('grep -rn "Taskearn" /var/www /etc/nginx /opt');
  console.log(res1.stdout || '(None found for Taskearn)');

  console.log('\n--- 2. Searching for "r2.dev" in /var/www and /etc/nginx ---');
  const res2 = await ssh.execCommand('grep -rn "r2.dev" /var/www /etc/nginx');
  console.log(res2.stdout || '(None found for r2.dev in /var/www /etc/nginx)');

  console.log('\n--- 3. Listing directories in /var/www ---');
  const res3 = await ssh.execCommand('ls -la /var/www');
  console.log(res3.stdout);

  console.log('\n--- 4. Checking Nginx sites-enabled / conf.d ---');
  const res4 = await ssh.execCommand('ls -la /etc/nginx/conf.d/');
  console.log(res4.stdout);

  ssh.dispose();
}

run();
