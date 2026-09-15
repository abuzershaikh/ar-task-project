const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function main() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('Resetting test withdrawal so user can test from Worker App...');
    await ssh.execCommand('mysql -e "DELETE FROM task_platform.withdrawals WHERE id=\'dd491409-966a-471c-9463-a3191f8a81da\';"');
    await ssh.execCommand('mysql -e "DELETE FROM task_platform.wallet_transactions WHERE reference_id=\'dd491409-966a-471c-9463-a3191f8a81da\';"');
    await ssh.execCommand('mysql -e "UPDATE task_platform.wallets SET available_balance=109.50, reserved_balance=0.00 WHERE user_id=\'kQzd3bZD7pgA908xGE6NoGogetB3\';"');

    const w = await ssh.execCommand('mysql -e "SELECT id, user_id, available_balance, reserved_balance FROM task_platform.wallets WHERE user_id=\'kQzd3bZD7pgA908xGE6NoGogetB3\';"');
    console.log('Wallet now:\n', w.stdout);

    const wt = await ssh.execCommand('mysql -e "SELECT * FROM task_platform.withdrawals;"');
    console.log('Withdrawals table now:\n', wt.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

main();
