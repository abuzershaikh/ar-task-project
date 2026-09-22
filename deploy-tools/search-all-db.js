const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function searchAllDb() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('--- SEARCHING FOR "dmarketer25" IN TASK_PLATFORM ---');
    const res1 = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT * FROM users WHERE email LIKE \'%dmarketer%\' OR email LIKE \'%wealth%\' OR email LIKE \'%groww%\';"');
    console.log(res1.stdout);

    console.log('--- SEARCHING FOR ANY BUYER IN TASK_PLATFORM ---');
    const res2 = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT * FROM users WHERE role = \'BUYER\';"');
    console.log(res2.stdout);

    console.log('--- SEARCHING IN WAPPBUZZ DATABASE ---');
    const res3 = await ssh.execCommand('mysql -u taskapp -ptaskapp_password wappbuzz -e "SHOW TABLES;"');
    console.log(res3.stdout);
    if (res3.stdout.trim()) {
      const res3b = await ssh.execCommand('mysql -u taskapp -ptaskapp_password wappbuzz -e "SELECT * FROM users;"');
      console.log(res3b.stdout);
    }

    console.log('--- SEARCHING ALL TABLES IN TASK_PLATFORM FOR ANY ROWS ---');
    const tblsRes = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SHOW TABLES;"');
    const tbls = tblsRes.stdout.trim().split('\n').slice(1).map(s => s.trim());
    for (const t of tbls) {
      const c = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "SELECT count(*) FROM ${t};"`);
      const count = c.stdout.trim().split('\n')[1].trim();
      if (parseInt(count) > 0) {
        console.log(`Table ${t}: ${count} rows`);
      }
    }

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

searchAllDb();
