const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function checkVPSDatabases() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== SHOW DATABASES (AS ROOT) ===');
    const dbs = await ssh.execCommand('mysql -e "SHOW DATABASES;"');
    console.log(dbs.stdout);

    console.log('=== TABLES IN WAPPBUZZ ===');
    const wpTables = await ssh.execCommand('mysql wappbuzz -e "SHOW TABLES;"');
    console.log(wpTables.stdout);

    console.log('=== ALL TABLES ACROSS ALL DBS WITH ROW COUNTS > 0 ===');
    const q = `
SELECT table_schema, table_name, table_rows 
FROM information_schema.tables 
WHERE table_schema NOT IN ('information_schema', 'mysql', 'performance_schema', 'sys')
AND table_rows > 0;
`;
    const rows = await ssh.execCommand(`mysql -e "${q.replace(/\n/g, ' ')}"`);
    console.log(rows.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

checkVPSDatabases();
