const { NodeSSH } = require('node-ssh');
const fs = require('fs');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 15000,
  });

  const content = fs.readFileSync('e:/pc2/android  project/Task  project/ar-task-project/deploy-tools/test-identity-urls.js', 'utf8');
  await ssh.execCommand(`cat << 'EOF' > /tmp/test_identity.js\n${content}\nEOF`);
  const res = await ssh.execCommand('node /tmp/test_identity.js');
  console.log(res.stdout, res.stderr);

  ssh.dispose();
}

run().catch(console.error);
