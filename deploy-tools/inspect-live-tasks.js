const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function inspectTasks() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== Active Tasks in Database ===');
    const res = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, order_id, campaign_id, order_unit_id, status, assigned_to, created_at FROM tasks WHERE status = 'ACTIVE' LIMIT 50;"`);
    console.log(res.stdout || '(No tasks found)');

    console.log('\n=== Recent Users in Database ===');
    const users = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, email, role, phone, created_at FROM users ORDER BY created_at DESC LIMIT 10;"`);
    console.log(users.stdout || '(No users)');

    console.log('\n=== Recent Task Assignments in Database ===');
    const assignments = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, task_id, worker_id, order_id, order_unit_id, status, created_at FROM task_assignments ORDER BY created_at DESC LIMIT 15;"`);
    console.log(assignments.stdout || '(No assignments)');

    console.log('\n=== Recent Campaign Worker Participations in Database ===');
    const parts = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "SELECT campaign_id, worker_id, status, participated_at FROM campaign_worker_participation ORDER BY participated_at DESC LIMIT 15;"`);
    console.log(parts.stdout || '(No participations)');

    console.log('\n=== Test available tasks for sonathe333@gmail.com ===');
    const apiRes1 = await ssh.execCommand(`curl -s -H "x-user-email: sonathe333@gmail.com" -H "x-user-id: kQzd3bZD7pgA908xGE6NoGogetB3" -H "x-user-role: WORKER" http://127.0.0.1:3000/api/v1/worker/tasks/available`);
    const p1 = JSON.parse(apiRes1.stdout);
    console.log('sonathe333 count:', p1.tasks?.length);
    for (const t of (p1.tasks || [])) {
      console.log(`- Task id: ${t.id}, orderId: ${t.orderId}, unitNumber: ${t.requirements?.unitNumber}`);
    }

    console.log('\n=== Test available tasks for brand new worker (with package dedup) ===');
    const apiResNew = await ssh.execCommand(`curl -s -H "x-user-email: brandnew_worker@gmail.com" -H "x-user-id: newworker999" -H "x-user-role: WORKER" http://127.0.0.1:3000/api/v1/worker/tasks/available`);
    const pNew = JSON.parse(apiResNew.stdout);
    console.log('brand new worker task count:', pNew.tasks?.length);
    for (const t of (pNew.tasks || [])) {
      console.log(`- Task id: ${t.id}, orderId: ${t.orderId}, app: ${t.requirements?.appName || t.requirements?.title}, unit: ${t.requirements?.unitNumber}, pkg: ${t.requirements?.packageId}`);
    }

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

inspectTasks();
