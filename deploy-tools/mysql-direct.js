const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== USERS ===');
    const u = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, email, full_name, role, is_active FROM users;"');
    console.log(u.stdout);

    console.log('=== WORKERS ===');
    const w = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, user_id, status, active_tasks_count, last_active_at, fcm_token IS NOT NULL AND fcm_token != \'\' as has_fcm, substring(fcm_token, 1, 25) as fcm_snip FROM workers;"');
    console.log(w.stdout);

    console.log('=== RECENT PARTICIPATIONS ===');
    const p = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT * FROM campaign_worker_participation ORDER BY participated_at DESC LIMIT 10;"');
    console.log(p.stdout);

    console.log('=== RECENT COMPLETED IDENTITIES ===');
    const i = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT * FROM worker_completed_identities ORDER BY created_at DESC LIMIT 10;"');
    console.log(i.stdout);

    console.log('=== RECENT 10 TASK ASSIGNMENTS ===');
    const ta = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT ta.id, ta.task_id, ta.worker_id, u.email, ta.status, ta.assigned_at, t.task_type FROM task_assignments ta LEFT JOIN workers w ON ta.worker_id = w.id LEFT JOIN users u ON w.user_id = u.id LEFT JOIN tasks t ON ta.task_id = t.id ORDER BY ta.assigned_at DESC LIMIT 10;"');
    console.log(ta.stdout);

  } catch (e) {
    console.error(e);
  } finally {
    ssh.dispose();
  }
}

run();
