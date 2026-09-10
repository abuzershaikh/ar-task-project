const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function main() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
    const users = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, email, phone, role, created_at FROM users;"`);
    console.log('USERS:\n', users.stdout);

    const workers = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, user_id, status FROM workers;"`);
    console.log('WORKERS:\n', workers.stdout);

    const settings = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "SELECT * FROM system_settings;"`);
    console.log('SYSTEM_SETTINGS:\n', settings.stdout);
  } catch (e) {
    console.error(e);
  } finally {
    ssh.dispose();
  }
}
main();
