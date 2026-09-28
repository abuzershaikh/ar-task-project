const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== APPLYING MYSQL PERFORMANCE INDEXES ===');
    const queries = [
      "ALTER TABLE tasks ADD INDEX idx_tasks_status_created (status, created_at);",
      "ALTER TABLE tasks ADD INDEX idx_tasks_order_status (order_id, status);",
      "ALTER TABLE tasks ADD INDEX idx_tasks_assigned_status (assigned_to, status);",
      "ALTER TABLE users ADD INDEX idx_users_role (role);"
    ];

    for (const q of queries) {
      console.log(`Running: ${q}`);
      const res = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "${q}"`);
      if (res.stdout) console.log('stdout:', res.stdout);
      if (res.stderr) {
        if (res.stderr.includes('Duplicate key name')) {
          console.log('Index already exists, skipping.');
        } else {
          console.error('stderr:', res.stderr);
        }
      }
    }

    console.log('\n=== VERIFYING TASKS INDEXES ===');
    const tasksIdx = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SHOW INDEX FROM tasks;"');
    console.log(tasksIdx.stdout);

    console.log('\n=== VERIFYING USERS INDEXES ===');
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
