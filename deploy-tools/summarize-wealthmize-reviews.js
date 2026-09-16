const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    const query = `
      SELECT 
        o.id as order_id,
        u.email as buyer_email,
        u.full_name as buyer_name,
        o.title as order_title,
        o.task_type,
        o.target_url,
        o.requirements as order_req,
        o.created_at
      FROM task_platform.orders o
      JOIN task_platform.users u ON o.buyer_id = u.id
      WHERE u.email IN ('growwyourwealthofficial@gmail.com', 'dmarketer25@gmail.com')
         OR u.full_name LIKE '%Wealthmize%'
      ORDER BY o.created_at DESC;
    `;

    const res = await ssh.execCommand(`mysql -e "${query.replace(/\n/g, ' ')}"`);
    console.log(res.stdout);

    console.log('\n--- FETCHING ALL GENERATED AI REVIEWS / COMMENTS PER ORDER ---');
    const tasksQuery = `
      SELECT 
        t.order_id,
        t.task_type,
        t.requirements
      FROM task_platform.tasks t
      JOIN task_platform.orders o ON t.order_id = o.id
      JOIN task_platform.users u ON o.buyer_id = u.id
      WHERE u.email IN ('growwyourwealthofficial@gmail.com', 'dmarketer25@gmail.com')
         OR u.full_name LIKE '%Wealthmize%'
      ORDER BY t.created_at ASC;
    `;

    const tasksRes = await ssh.execCommand(`mysql -e "${tasksQuery.replace(/\n/g, ' ')}"`);
    const lines = tasksRes.stdout.split('\n');
    // We can parse or dump in JSON format
    const dumpScript = `
const mysql = require('mysql2/promise');
async function main() {
  const conn = await mysql.createConnection({
    host: 'localhost',
    user: 'root',
    database: 'task_platform'
  });
  
  const [rows] = await conn.execute(\`
    SELECT 
      o.id as order_id,
      u.email as buyer_email,
      u.full_name as buyer_name,
      o.title as order_title,
      o.task_type,
      o.target_url,
      t.id as task_id,
      t.requirements
    FROM task_platform.tasks t
    JOIN task_platform.orders o ON t.order_id = o.id
    JOIN task_platform.users u ON o.buyer_id = u.id
    WHERE u.email IN ('growwyourwealthofficial@gmail.com', 'dmarketer25@gmail.com')
       OR u.full_name LIKE '%Wealthmize%'
    ORDER BY o.created_at DESC, t.created_at ASC;
  \`);
  
  const byOrder = {};
  for (const r of rows) {
    if (!byOrder[r.order_id]) {
      byOrder[r.order_id] = {
        orderId: r.order_id,
        buyerEmail: r.buyer_email,
        buyerName: r.buyer_name,
        title: r.order_title,
        taskType: r.task_type,
        targetUrl: r.target_url,
        sampleComments: [],
        assignedComments: []
      };
    }
    const req = typeof r.requirements === 'string' ? JSON.parse(r.requirements) : r.requirements;
    if (req && req.sampleComments && byOrder[r.order_id].sampleComments.length === 0) {
      byOrder[r.order_id].sampleComments = req.sampleComments;
    }
    if (req && req.commentText) {
      byOrder[r.order_id].assignedComments.push(req.commentText);
    }
  }
  
  console.log(JSON.stringify(byOrder, null, 2));
  await conn.end();
}
main().catch(console.error);
    `;

    await ssh.execCommand(`cat << 'EOF' > /opt/task-engine/dump-reviews.js\n${dumpScript}\nEOF\n`);
    const dumpRes = await ssh.execCommand('node /opt/task-engine/dump-reviews.js', { cwd: '/opt/task-engine' });
    console.log(dumpRes.stdout);
    await ssh.execCommand('rm -f /opt/task-engine/dump-reviews.js');

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

run();
