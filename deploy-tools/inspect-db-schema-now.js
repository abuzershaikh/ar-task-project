const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
      readyTimeout: 60000,
    });

    console.log('--- ALL TABLES ---');
    const tRes = await ssh.execCommand("mysql -e 'SHOW TABLES IN task_platform;'");
    console.log(tRes.stdout);

    console.log('--- COLUMNS OF WALLET_TRANSACTIONS ---');
    const c1 = await ssh.execCommand("mysql -e 'DESCRIBE task_platform.wallet_transactions;'");
    console.log(c1.stdout);

    console.log('--- COLUMNS OF TRANSACTIONS ---');
    const c2 = await ssh.execCommand("mysql -e 'DESCRIBE task_platform.transactions;'");
    console.log(c2.stdout);

    console.log('--- COLUMNS OF ORDERS ---');
    const c3 = await ssh.execCommand("mysql -e 'DESCRIBE task_platform.orders;'");
    console.log(c3.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

run();
