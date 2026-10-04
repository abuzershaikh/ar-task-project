const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== DATABASE DISK SIZE (task_platform) ===');
    const dbSize = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password -e "SELECT table_schema AS 'Database', ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size_MB' FROM information_schema.tables WHERE table_schema = 'task_platform' GROUP BY table_schema;"`);
    console.log(dbSize.stdout);

    console.log('=== TOP 5 LARGEST TABLES IN task_platform ===');
    const topTables = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password -e "SELECT table_name AS 'Table', ROUND(((data_length + index_length) / 1024 / 1024), 2) AS 'Size_MB' FROM information_schema.TABLES WHERE table_schema = 'task_platform' ORDER BY (data_length + index_length) DESC LIMIT 5;"`);
    console.log(topTables.stdout);

    console.log('=== MYSQL PROCESS RAM USAGE ===');
    const ram = await ssh.execCommand(`ps aux | grep -E 'mysqld|mariadbd' | grep -v grep | awk '{print "Process: " $11, "| RAM: " $6/1024 " MB", "| %MEM: " $4 "%"}'`);
    console.log(ram.stdout);

  } catch (e) {
    console.error(e);
  } finally {
    ssh.dispose();
  }
}

run();
