const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 15000,
  });

  const res = await ssh.execCommand('export PATH=$PATH:/usr/local/bin:/usr/bin:~/.nvm/versions/node/$(ls ~/.nvm/versions/node 2>/dev/null | tail -n 1)/bin; pm2 list; systemctl status task-engine || ps aux | grep node');
  console.log(res.stdout);

  ssh.dispose();
}

run().catch(console.error);
