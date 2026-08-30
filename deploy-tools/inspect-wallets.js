const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function inspectWallets() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    const wt = await ssh.execCommand('mysql -e "DESCRIBE task_platform.wallet_transactions;"');
    console.log('wallet_transactions columns:\n', wt.stdout);

    const w = await ssh.execCommand('mysql -e "DESCRIBE task_platform.wallets;"');
    console.log('wallets columns:\n', w.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

inspectWallets();
