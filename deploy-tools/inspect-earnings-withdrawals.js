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

    console.log('=== EARNINGS TABLE SCHEMA ===');
    const eDesc = await ssh.execCommand("mysql -e 'DESCRIBE task_platform.earnings;'");
    console.log(eDesc.stdout);

    console.log('=== WITHDRAWALS TABLE SCHEMA ===');
    const wDesc = await ssh.execCommand("mysql -e 'DESCRIBE task_platform.withdrawals;'");
    console.log(wDesc.stdout);

    console.log('=== EARNINGS FOR SONATHE ===');
    const eRows = await ssh.execCommand("mysql -e 'SELECT * FROM task_platform.earnings WHERE worker_id = \"MYDovhuR8zcbLlvazaAG8qdWLXr1\" OR worker_id = \"2a718708-c51e-44b2-a175-a614286321b4\";'");
    console.log(eRows.stdout);

    console.log('=== ALL EARNINGS (LIMIT 5) ===');
    const eAll = await ssh.execCommand("mysql -e 'SELECT * FROM task_platform.earnings ORDER BY created_at DESC LIMIT 5;'");
    console.log(eAll.stdout);

    console.log('=== ALL WITHDRAWALS (LIMIT 5) ===');
    const wAll = await ssh.execCommand("mysql -e 'SELECT * FROM task_platform.withdrawals ORDER BY created_at DESC LIMIT 5;'");
    console.log(wAll.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

run();
