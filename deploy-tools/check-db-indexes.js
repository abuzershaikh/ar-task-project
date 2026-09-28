const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== TASKS TABLE INDEXES ===');
    const tasksIdx = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SHOW INDEX FROM tasks;"');
    console.log(tasksIdx.stdout);

    console.log('=== TASK_ASSIGNMENTS INDEXES ===');
    const assignIdx = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SHOW INDEX FROM task_assignments;"');
    console.log(assignIdx.stdout);

    console.log('=== USERS INDEXES ===');
    const usersIdx = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SHOW INDEX FROM users;"');
    console.log(usersIdx.stdout);

  } catch (e) {
    console.error('Error:', e.message);
  } finally {
    ssh.dispose();
    process.exit(0);
  }
}

run();
