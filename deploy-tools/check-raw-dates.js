const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
    const alterRes = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "
      ALTER TABLE task_assignments ADD COLUMN IF NOT EXISTS order_unit_id varchar(255) DEFAULT NULL;
      ALTER TABLE task_assignments ADD COLUMN IF NOT EXISTS order_id varchar(255) DEFAULT NULL;
      ALTER TABLE tasks ADD COLUMN IF NOT EXISTS order_unit_id varchar(255) DEFAULT NULL;
      DESCRIBE task_assignments;
    "`);
    console.log('ALTER & DESCRIBE:\n', alterRes.stdout);
  } catch (e) {
    console.error(e);
  } finally {
    ssh.dispose();
  }
}
run();
