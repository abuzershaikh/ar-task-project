const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('--- LOCAL HEALTH ---');
    const localHealth = await ssh.execCommand('curl -s -m 5 http://127.0.0.1:3000/api/v1/health');
    console.log('Local API Health:', localHealth.stdout || localHealth.stderr);

    console.log('\n--- DOMAIN HEALTH (reviewsgateway.in) ---');
    const domainHealth = await ssh.execCommand('curl -s -m 5 https://reviewsgateway.in/api/v1/health');
    console.log('Domain API Health:', domainHealth.stdout || domainHealth.stderr);

    console.log('\n--- DOMAIN ROOT ---');
    const domainRoot = await ssh.execCommand('curl -s -I -m 5 https://reviewsgateway.in/');
    console.log('Domain Root Headers:\n', domainRoot.stdout || domainRoot.stderr);

    console.log('\n--- PM2 OVERVIEW ---');
    const pm2 = await ssh.execCommand('pm2 list');
    console.log(pm2.stdout);

  } catch (e) {
    console.error('Error:', e.message);
  } finally {
    ssh.dispose();
    process.exit(0);
  }
}

run();
