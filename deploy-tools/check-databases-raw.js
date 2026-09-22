const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function checkDatabases() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('--- SHOW DATABASES ---');
    const dbs = await ssh.execCommand('mysql -u taskapp -ptaskapp_password -e "SHOW DATABASES;"');
    console.log(dbs.stdout);

    console.log('--- TABLES IN task_platform ---');
    const tables = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SHOW TABLES;"');
    console.log(tables.stdout);

    console.log('--- COUNT OF USERS ---');
    const uCount = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT count(*) FROM users;"');
    console.log(uCount.stdout);

    console.log('--- ALL USERS RAW ---');
    const uAll = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT * FROM users\\G"');
    console.log(uAll.stdout);

    console.log('--- COUNT OF WORKERS ---');
    const wCount = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT count(*) FROM workers;"');
    console.log(wCount.stdout);

    console.log('--- ALL WORKERS RAW ---');
    const wAll = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT * FROM workers\\G"');
    console.log(wAll.stdout);

    // Is there any other database on VPS?
    console.log('--- ROOT MYSQL DATABASES ---');
    const rootDbs = await ssh.execCommand('mysql -e "SHOW DATABASES;"');
    console.log(rootDbs.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

checkDatabases();
