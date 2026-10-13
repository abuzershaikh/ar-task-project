const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

(async () => {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    const script = `
const mysql = require('mysql2/promise');

async function run() {
  const pool = await mysql.createPool({
    host: 'localhost',
    user: 'taskapp',
    password: 'taskapp_password',
    database: 'task_platform',
  });

  console.time('scalar_join_query');
  const [rows] = await pool.query(\`
      SELECT c.*, 
             COALESCE(NULLIF(NULLIF(c.worker_name, 'Worker'), ''), u.full_name, w.full_name, u.email, 'Worker') as worker_name,
             COALESCE(NULLIF(c.worker_email, ''), u.email, '') as worker_email,
             COALESCE(NULLIF(c.worker_phone, ''), u.phone, w.phone, '') as worker_phone,
             COALESCE(NULLIF(c.worker_avatar_url, ''), u.avatar_url) as worker_avatar_url,
             COALESCE(w.id, c.worker_id) as worker_actual_id,
             w.last_active_at, 
             COALESCE(w.total_tasks_completed, 0) as total_tasks_completed, 
             w.status as worker_status
      FROM support_conversations c
      LEFT JOIN users u ON u.id = (
        SELECT id FROM users 
        WHERE id = c.worker_id OR (c.worker_email != '' AND email = c.worker_email)
        ORDER BY CASE WHEN id = c.worker_id THEN 1 ELSE 2 END 
        LIMIT 1
      )
      LEFT JOIN workers w ON w.id = (
        SELECT id FROM workers 
        WHERE user_id = c.worker_id OR user_id = u.id OR id = c.worker_id
        ORDER BY total_tasks_completed DESC, last_active_at DESC, created_at DESC 
        LIMIT 1
      )
      ORDER BY c.last_message_at DESC
      LIMIT 100 OFFSET 0
  \`);
  console.timeEnd('scalar_join_query');

  console.log('Returned rows:', rows.length);
  const naxmRows = rows.filter(r => r.worker_email === 'workinhomex@gmail.com' || (r.worker_name && r.worker_name.includes('Naxm')));
  console.log('Naxm Glitch count in top 100:', naxmRows.length);
  if (naxmRows.length > 0) {
    console.log('Naxm Glitch row:', {
      id: naxmRows[0].id,
      worker_name: naxmRows[0].worker_name,
      worker_email: naxmRows[0].worker_email,
      worker_actual_id: naxmRows[0].worker_actual_id,
      total_tasks_completed: naxmRows[0].total_tasks_completed
    });
  }

  // Also test with search query
  console.time('search_query');
  const [searchRows] = await pool.query(\`
      SELECT c.*, 
             COALESCE(NULLIF(NULLIF(c.worker_name, 'Worker'), ''), u.full_name, w.full_name, u.email, 'Worker') as worker_name,
             COALESCE(NULLIF(c.worker_email, ''), u.email, '') as worker_email,
             COALESCE(NULLIF(c.worker_phone, ''), u.phone, w.phone, '') as worker_phone,
             COALESCE(NULLIF(c.worker_avatar_url, ''), u.avatar_url) as worker_avatar_url,
             COALESCE(w.id, c.worker_id) as worker_actual_id,
             w.last_active_at, 
             COALESCE(w.total_tasks_completed, 0) as total_tasks_completed, 
             w.status as worker_status
      FROM support_conversations c
      LEFT JOIN users u ON u.id = (
        SELECT id FROM users 
        WHERE id = c.worker_id OR (c.worker_email != '' AND email = c.worker_email)
        ORDER BY CASE WHEN id = c.worker_id THEN 1 ELSE 2 END 
        LIMIT 1
      )
      LEFT JOIN workers w ON w.id = (
        SELECT id FROM workers 
        WHERE user_id = c.worker_id OR user_id = u.id OR id = c.worker_id
        ORDER BY total_tasks_completed DESC, last_active_at DESC, created_at DESC 
        LIMIT 1
      )
      WHERE (
        COALESCE(NULLIF(NULLIF(c.worker_name, 'Worker'), ''), u.full_name, 'Worker') LIKE '%Naxm%' 
        OR u.email LIKE '%Naxm%' 
        OR c.worker_email LIKE '%Naxm%' 
        OR c.worker_phone LIKE '%Naxm%' 
        OR u.phone LIKE '%Naxm%' 
        OR c.last_message_text LIKE '%Naxm%'
      )
      ORDER BY c.last_message_at DESC
      LIMIT 100 OFFSET 0
  \`);
  console.timeEnd('search_query');
  console.log('Search returned rows for Naxm:', searchRows.length);

  await pool.end();
}

run().then(() => process.exit(0)).catch(e => { console.error(e); process.exit(1); });
    `;

    await ssh.execCommand("cat << 'EOF' > /root/test_query_fix.js\n" + script + "\nEOF");
    const res = await ssh.execCommand('NODE_PATH=/opt/task-engine/node_modules node /root/test_query_fix.js');
    console.log(res.stdout);
    if (res.stderr) console.error(res.stderr);

    ssh.dispose();
  } catch (e) {
    console.error(e);
  }
})();
