const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 30000,
  });

  const sql = `
    SELECT 
      assigned_to,
      COUNT(*) as times_done,
      GROUP_CONCAT(order_id) as order_ids,
      GROUP_CONCAT(status) as statuses
    FROM tasks
    WHERE (requirements LIKE '%autopaycancel.autopaymanager%' OR requirements LIKE '%com.wealthmize.autopaycancel%')
      AND assigned_to IS NOT NULL
    GROUP BY assigned_to
    HAVING times_done > 1;
  `;
  
  await ssh.execCommand(`cat << 'EOF' > /tmp/check_repeat_workers.sql\n${sql}\nEOF`);
  const res = await ssh.execCommand('mysql task_platform < /tmp/check_repeat_workers.sql');
  console.log('Workers who did autopaycancel multiple times:\n', res.stdout);

  const sql2 = `
    SELECT 
      assigned_to,
      COUNT(*) as times_done,
      GROUP_CONCAT(order_id) as order_ids,
      GROUP_CONCAT(status) as statuses
    FROM tasks
    WHERE requirements LIKE '%HOTEL BNB PALACE%'
      AND assigned_to IS NOT NULL
    GROUP BY assigned_to
    HAVING times_done > 1;
  `;
  
  await ssh.execCommand(`cat << 'EOF' > /tmp/check_repeat_gmb_workers.sql\n${sql2}\nEOF`);
  const res2 = await ssh.execCommand('mysql task_platform < /tmp/check_repeat_gmb_workers.sql');
  console.log('Workers who did HOTEL BNB PALACE multiple times:\n', res2.stdout);

  ssh.dispose();
}

run().catch(console.error);
