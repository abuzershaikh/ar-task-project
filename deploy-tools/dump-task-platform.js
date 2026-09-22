const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function dumpAllTaskPlatform() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    const tablesRes = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SHOW TABLES;"');
    const tables = tablesRes.stdout.trim().split('\n').slice(1).map(s => s.trim());

    console.log('=== DUMPING EVERY ROW OF NON-EMPTY TABLES IN TASK_PLATFORM ===\n');

    for (const table of tables) {
      if (['migrations', 'system_settings', 'service_pricing'].includes(table)) continue; // skip huge static tables

      const res = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "SELECT * FROM \\\`${table}\\\`;"`);
      const output = res.stdout.trim();
      const lineCount = output ? output.split('\n').length : 0;
      if (lineCount > 1) {
        console.log(`>>> TABLE: ${table} (${lineCount - 1} rows) <<<`);
        console.log(output);
        console.log('\n----------------------------------------\n');
      } else {
        console.log(`TABLE: ${table} is EMPTY (0 rows)`);
      }
    }

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

dumpAllTaskPlatform();
