const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    const res = await ssh.execCommand(`mysql -e "SELECT id, DATE_FORMAT(created_at, '%Y-%m-%d %H:%i:%s') as created_at FROM task_platform.wallet_transactions WHERE description LIKE '%pay_TmG4hn8lJ31xYY%';"`);
    console.log(res.stdout);

  } catch (e) {
    console.error(e);
  } finally {
    ssh.dispose();
  }
}

run();
