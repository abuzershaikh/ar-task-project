const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function check() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('Connected to VPS.');

    console.log('\n--- Checking Nginx Response for swiftcommerce.in & www ---');
    const curlLocal = await ssh.execCommand('curl -sI -H "Host: swiftcommerce.in" http://127.0.0.1');
    console.log('swiftcommerce.in HTTP response:\n', curlLocal.stdout);

    const curlWww = await ssh.execCommand('curl -sI -H "Host: www.swiftcommerce.in" http://127.0.0.1');
    console.log('www.swiftcommerce.in HTTP response:\n', curlWww.stdout);

    console.log('\n--- DIG +trace swiftcommerce.in ---');
    const digTrace = await ssh.execCommand('dig +trace swiftcommerce.in');
    console.log(digTrace.stdout || digTrace.stderr);

    console.log('\n--- WHOIS swiftcommerce.in ---');
    let whoisRes = await ssh.execCommand('whois swiftcommerce.in');
    if (!whoisRes.stdout || whoisRes.stdout.includes('command not found')) {
      await ssh.execCommand('dnf install -y whois bind-utils');
      whoisRes = await ssh.execCommand('whois swiftcommerce.in');
    }
    console.log(whoisRes.stdout || whoisRes.stderr);

  } catch (e) {
    console.error('Error:', e.message);
  } finally {
    ssh.dispose();
    process.exit(0);
  }
}

check();
