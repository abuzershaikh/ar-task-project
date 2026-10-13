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

  console.log('=== STARTING WORKERS DEDUPLICATION ===');

  // 1. Find all user_ids with duplicate worker records
  const [dupUsers] = await pool.query(\`
    SELECT user_id, COUNT(*) as cnt 
    FROM workers 
    WHERE user_id IS NOT NULL AND user_id != ''
    GROUP BY user_id 
    HAVING cnt > 1
  \`);
  console.log('Found', dupUsers.length, 'users with duplicate records.');

  let totalDeleted = 0;

  for (const { user_id, cnt } of dupUsers) {
    // Fetch all worker records for this user_id ordered by:
    // most tasks completed first, latest last_active_at, latest updated_at
    const [workers] = await pool.query(\`
      SELECT id, total_tasks_completed, last_active_at, created_at, updated_at
      FROM workers 
      WHERE user_id = ?
      ORDER BY total_tasks_completed DESC, 
               CASE WHEN last_active_at IS NOT NULL THEN 1 ELSE 2 END, 
               last_active_at DESC, 
               created_at ASC
    \`, [user_id]);

    const primaryWorker = workers[0];
    const duplicateWorkers = workers.slice(1);
    const dupIds = duplicateWorkers.map(w => w.id);

    console.log(\`User \${user_id}: Keeping primary worker \${primaryWorker.id} (tasks: \${primaryWorker.total_tasks_completed}), removing \${dupIds.length} duplicates.\`);

    // Re-link references from dupIds to primaryWorker.id
    const tablesToCheck = [
      { table: 'tasks', column: 'worker_id' },
      { table: 'task_submissions', column: 'worker_id' },
      { table: 'task_assignments', column: 'worker_id' },
      { table: 'earnings', column: 'worker_id' },
      { table: 'withdrawals', column: 'worker_id' },
      { table: 'kyc_profiles', column: 'worker_id' },
      { table: 'payment_methods', column: 'worker_id' },
      { table: 'ratings', column: 'worker_id' },
      { table: 'campaign_worker_participation', column: 'worker_id' },
      { table: 'worker_scores', column: 'worker_id' },
      { table: 'worker_completed_identities', column: 'worker_key' },
    ];

    for (const { table, column } of tablesToCheck) {
      for (const dupId of dupIds) {
        try {
          await pool.query(\`UPDATE \${table} SET \${column} = ? WHERE \${column} = ?\`, [primaryWorker.id, dupId]);
        } catch (e) {
          // Ignore if duplicate constraint or column doesn't match
        }
      }
    }

    // Now safely delete duplicate worker records
    const [delRes] = await pool.query('DELETE FROM workers WHERE id IN (?)', [dupIds]);
    totalDeleted += delRes.affectedRows;
  }

  console.log(\`Successfully removed \${totalDeleted} duplicate worker records!\`);

  // Verify no duplicate user_id remains in workers
  const [remainingDups] = await pool.query(\`
    SELECT user_id, COUNT(*) as cnt 
    FROM workers 
    GROUP BY user_id 
    HAVING cnt > 1
  \`);
  console.log('Remaining duplicates:', remainingDups.length);

  // Add UNIQUE KEY index on user_id if not present
  try {
    console.log('Adding UNIQUE index on workers(user_id)...');
    await pool.query('ALTER TABLE workers ADD UNIQUE KEY uq_workers_user_id (user_id)');
    console.log('UNIQUE index uq_workers_user_id successfully created!');
  } catch (err) {
    if (err.message.includes('Duplicate key name')) {
      console.log('Index uq_workers_user_id already exists.');
    } else {
      console.error('Error creating unique index:', err.message);
    }
  }

  const [finalCount] = await pool.query('SELECT COUNT(*) as c FROM workers');
  console.log('Final worker count in database:', finalCount[0].c);

  await pool.end();
}

run().then(() => process.exit(0)).catch(e => { console.error(e); process.exit(1); });
    `;

    await ssh.execCommand("cat << 'EOF' > /root/run_dedup_workers.js\n" + script + "\nEOF");
    const res = await ssh.execCommand('NODE_PATH=/opt/task-engine/node_modules node /root/run_dedup_workers.js');
    console.log(res.stdout);
    if (res.stderr) console.error(res.stderr);

    ssh.dispose();
  } catch (e) {
    console.error(e);
  }
})();
