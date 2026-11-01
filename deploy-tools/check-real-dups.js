const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 15000,
  });

  console.log('--- Checking Play Store tasks where same worker got multiple tasks ---');
  const playDups = await ssh.execCommand(`
    SELECT assigned_to, COUNT(*) as cnt, 
           JSON_UNQUOTE(JSON_EXTRACT(requirements, '$.packageId')) as pkg,
           JSON_UNQUOTE(JSON_EXTRACT(requirements, '$.targetUrl')) as url
    FROM tasks
    WHERE task_type LIKE '%PLAY%' AND assigned_to IS NOT NULL
    GROUP BY assigned_to, pkg
    HAVING cnt > 1
    ORDER BY cnt DESC LIMIT 10;
  `);
  console.log('Play Store dups:\n', playDups.stdout);

  console.log('--- Checking Google Business tasks where same worker got multiple tasks ---');
  const gmbDups = await ssh.execCommand(`
    SELECT assigned_to, COUNT(*) as cnt, 
           JSON_UNQUOTE(JSON_EXTRACT(requirements, '$.targetUrl')) as url,
           JSON_UNQUOTE(JSON_EXTRACT(requirements, '$.businessName')) as bName
    FROM tasks
    WHERE (task_type LIKE '%GOOGLE%' OR task_type LIKE '%GMB%') AND assigned_to IS NOT NULL
    GROUP BY assigned_to, url
    HAVING cnt > 1
    ORDER BY cnt DESC LIMIT 10;
  `);
  console.log('GMB dups by url:\n', gmbDups.stdout);

  console.log('--- Checking Google Business tasks where same worker got tasks for same business name ---');
  const gmbDupsName = await ssh.execCommand(`
    SELECT assigned_to, COUNT(*) as cnt, 
           JSON_UNQUOTE(JSON_EXTRACT(requirements, '$.businessName')) as bName
    FROM tasks
    WHERE (task_type LIKE '%GOOGLE%' OR task_type LIKE '%GMB%') AND assigned_to IS NOT NULL
    GROUP BY assigned_to, bName
    HAVING cnt > 1 AND bName IS NOT NULL AND bName != ''
    ORDER BY cnt DESC LIMIT 10;
  `);
  console.log('GMB dups by business name:\n', gmbDupsName.stdout);

  ssh.dispose();
}

run().catch(console.error);
