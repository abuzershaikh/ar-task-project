const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  console.log('=== LATEST 100 LINES OF task-engine-api-error-0.log ===');
  const errLog = await ssh.execCommand('tail -n 100 /root/.pm2/logs/task-engine-api-error-0.log');
  console.log(errLog.stdout);

  console.log('\n=== RECENT ERROR/EXCEPTION IN task-engine-api-out-0.log ===');
  const outErr = await ssh.execCommand('grep -i -E "error|exception|fail" /root/.pm2/logs/task-engine-api-out-0.log | tail -n 50');
  console.log(outErr.stdout);

  console.log('\n=== RECENT BUYER WALLET / BALANCE REQUESTS IN API OUT LOG ===');
  const walletLog = await ssh.execCommand('grep -i -E "wallet|balance|deposit|razorpay|buyer" /root/.pm2/logs/task-engine-api-out-0.log | tail -n 50');
  console.log(walletLog.stdout);

  ssh.dispose();
}

run();
