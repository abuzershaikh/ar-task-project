const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

(async () => {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    const runSql = async (sql) => {
      await ssh.execCommand(`cat << 'EOF' > /tmp/query.sql\n${sql}\nEOF`);
      const res = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform < /tmp/query.sql');
      return res.stdout || res.stderr;
    };

    const orderPrefix = '732cbd88%';

    console.log('--- ALL CATEGORIES & SERVICES IN DB ---');
    console.log(await runSql(`
      SELECT DISTINCT category, code, name FROM service_catalog ORDER BY category, code;
    `));




    console.log('\n--- 2. ASSIGNMENT TIMELINE SUMMARY (BY DATE) ---');
    console.log(await runSql(`
      SELECT DATE(ta.created_at) as assign_date,
             COUNT(*) as total_assigned,
             SUM(CASE WHEN ta.status IN ('COMPLETED', 'SUBMITTED') THEN 1 ELSE 0 END) as completed_or_submitted,
             SUM(CASE WHEN ta.status = 'EARLY_RELEASED' THEN 1 ELSE 0 END) as released,
             SUM(CASE WHEN ta.status IN ('ASSIGNED', 'STARTED') THEN 1 ELSE 0 END) as in_progress
      FROM task_assignments ta
      WHERE ta.campaign_id LIKE '${orderPrefix}' OR ta.order_id LIKE '${orderPrefix}'
      GROUP BY DATE(ta.created_at)
      ORDER BY assign_date DESC;
    `));

    console.log('\n--- 3. TODAY (OCT 4) ASSIGNMENTS & WORKERS ---');
    console.log(await runSql(`
      SELECT ta.id as assignment_id, ta.task_id, ta.worker_id, u.full_name, u.email,
             u.created_at as user_registered_at,
             DATEDIFF('2026-10-04', DATE(u.created_at)) as user_age_days,
             ta.status as assignment_status, ta.created_at as assigned_at, ta.submitted_at
      FROM task_assignments ta
      LEFT JOIN users u ON (u.id = ta.worker_id OR u.email = ta.worker_id)
      WHERE (ta.campaign_id LIKE '${orderPrefix}' OR ta.order_id LIKE '${orderPrefix}')
        AND DATE(ta.created_at) = '2026-10-04'
      ORDER BY ta.created_at DESC;
    `));

    console.log('\n--- 4. YESTERDAY (OCT 3) ASSIGNMENTS & WORKERS ---');
    console.log(await runSql(`
      SELECT ta.id as assignment_id, ta.task_id, ta.worker_id, u.full_name, u.email,
             u.created_at as user_registered_at,
             DATEDIFF('2026-10-03', DATE(u.created_at)) as user_age_days,
             ta.status as assignment_status, ta.created_at as assigned_at, ta.submitted_at
      FROM task_assignments ta
      LEFT JOIN users u ON (u.id = ta.worker_id OR u.email = ta.worker_id)
      WHERE (ta.campaign_id LIKE '${orderPrefix}' OR ta.order_id LIKE '${orderPrefix}')
        AND DATE(ta.created_at) = '2026-10-03'
      ORDER BY ta.created_at DESC;
    `));

    console.log('\n--- 5. ALL TIME ASSIGNMENTS: NEW WORKERS (REGISTERED IN OCT) VS OLD WORKERS ---');
    console.log(await runSql(`
      SELECT 
        CASE 
          WHEN u.created_at >= '2026-10-01 00:00:00' THEN 'NEW_WORKER_OCT'
          ELSE 'OLD_WORKER_PRE_OCT'
        END as worker_category,
        COUNT(DISTINCT ta.worker_id) as unique_workers,
        COUNT(ta.id) as total_assignments,
        SUM(CASE WHEN ta.status IN ('COMPLETED', 'SUBMITTED') THEN 1 ELSE 0 END) as successful_submissions
      FROM task_assignments ta
      LEFT JOIN users u ON (u.id = ta.worker_id OR u.email = ta.worker_id)
      WHERE ta.campaign_id LIKE '${orderPrefix}' OR ta.order_id LIKE '${orderPrefix}'
      GROUP BY worker_category;
    `));

    console.log('\n--- 6. REMAINING ACTIVE/UNASSIGNED TASKS FOR THIS ORDER ---');
    console.log(await runSql(`
      SELECT COUNT(*) as unassigned_tasks_remaining
      FROM tasks t
      WHERE t.order_id LIKE '${orderPrefix}'
        AND t.status = 'active'
        AND (t.assigned_to IS NULL OR t.assigned_to = '');
    `));




    ssh.dispose();
  } catch (err) {
    console.error('Error:', err);
    ssh.dispose();
  }
})();
