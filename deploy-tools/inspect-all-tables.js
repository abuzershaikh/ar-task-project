const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function inspectAllTables() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('--- ALL TABLES AND ROW COUNTS IN task_platform ---');
    const res = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "
      SELECT table_name, table_rows 
      FROM information_schema.tables 
      WHERE table_schema = 'task_platform' 
      ORDER BY table_name;
    "`);
    console.log(res.stdout);

    console.log('--- USERS BY ROLE ---');
    const users = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "
      SELECT role, count(*) as count FROM users GROUP BY role;
    "`);
    console.log(users.stdout);

    console.log('--- ADMIN USERS ---');
    const admins = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "
      SELECT id, email, role, createdAt FROM users WHERE role = 'SUPER_ADMIN' OR role = 'ADMIN';
    "`);
    console.log(admins.stdout);

    console.log('--- TABLES SCHEMAS & FOREIGN KEYS ---');
    const fk = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "
      SELECT TABLE_NAME, COLUMN_NAME, CONSTRAINT_NAME, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME
      FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
      WHERE TABLE_SCHEMA = 'task_platform' AND REFERENCED_TABLE_NAME IS NOT NULL;
    "`);
    console.log(fk.stdout);

  } catch (err) {
    console.error('Error:', err);
  } finally {
    ssh.dispose();
  }
}

inspectAllTables();
