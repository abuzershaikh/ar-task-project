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
      t.assigned_to,
      COUNT(*) as count,
      t.task_type,
      JSON_UNQUOTE(JSON_EXTRACT(t.requirements, '$.targetUrl')) as url,
      JSON_UNQUOTE(JSON_EXTRACT(t.requirements, '$.packageId')) as pkg,
      JSON_UNQUOTE(JSON_EXTRACT(t.requirements, '$.appName')) as appName,
      JSON_UNQUOTE(JSON_EXTRACT(t.requirements, '$.businessName')) as businessName
    FROM tasks t
    WHERE t.assigned_to IS NOT NULL 
      AND t.status IN ('assigned', 'accepted', 'in_progress', 'submitted', 'under_review', 'approved', 'completed')
      AND (t.task_type LIKE '%PLAY%' OR t.task_type LIKE '%GOOGLE%' OR t.task_type LIKE '%GMB%' OR t.task_type LIKE '%APP%')
    GROUP BY t.assigned_to, url
    HAVING count > 1
    ORDER BY count DESC
    LIMIT 20;
  `;
  
  await ssh.execCommand(`cat << 'EOF' > /tmp/check_all_dups.sql\n${sql}\nEOF`);
  const res = await ssh.execCommand('mysql task_platform < /tmp/check_all_dups.sql');
  console.log('Duplicate assignments for same URL and worker:\n', res.stdout);

  const sql2 = `
    SELECT 
      t.assigned_to,
      COUNT(*) as count,
      t.task_type,
      JSON_UNQUOTE(JSON_EXTRACT(t.requirements, '$.packageId')) as pkg
    FROM tasks t
    WHERE t.assigned_to IS NOT NULL 
      AND t.status IN ('assigned', 'accepted', 'in_progress', 'submitted', 'under_review', 'approved', 'completed')
      AND (t.task_type LIKE '%PLAY%' OR t.task_type LIKE '%APP%')
      AND JSON_EXTRACT(t.requirements, '$.packageId') IS NOT NULL
      AND JSON_UNQUOTE(JSON_EXTRACT(t.requirements, '$.packageId')) != 'null'
      AND JSON_UNQUOTE(JSON_EXTRACT(t.requirements, '$.packageId')) != ''
    GROUP BY t.assigned_to, pkg
    HAVING count > 1
    ORDER BY count DESC
    LIMIT 20;
  `;
  
  await ssh.execCommand(`cat << 'EOF' > /tmp/check_all_pkg_dups.sql\n${sql2}\nEOF`);
  const res2 = await ssh.execCommand('mysql task_platform < /tmp/check_all_pkg_dups.sql');
  console.log('Duplicate assignments for same packageId and worker:\n', res2.stdout);

  ssh.dispose();
}

run().catch(console.error);
