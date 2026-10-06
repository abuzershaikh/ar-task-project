const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function main() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  console.log('--- SUPPORT CONVERSATIONS (FIRST 15) ---');
  const sc = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, worker_id, worker_name, worker_email, worker_phone FROM support_conversations ORDER BY id DESC LIMIT 15;"`);
  console.log(sc.stdout);

  console.log('--- DESCRIBE USERS ---');
  const du = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "DESCRIBE users;"`);
  console.log(du.stdout);

  console.log('--- DESCRIBE WORKERS ---');
  const dw = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "DESCRIBE workers;"`);
  console.log(dw.stdout);

  console.log('--- SEARCH FOR FIREBASE UID IN ALL TABLES ---');
  const findUid = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "
    SELECT 'users' as tbl, id, full_name, email FROM users WHERE id LIKE '%CKQx%' OR email LIKE '%CKQx%';
    SELECT 'workers' as tbl, id, user_id, full_name, email FROM workers WHERE id LIKE '%CKQx%' OR user_id LIKE '%CKQx%';
  "`);
  console.log(findUid.stdout);


  console.log('--- TOTAL CONVERSATIONS WITH/WITHOUT NAME ---');
  const stats = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "SELECT 
    COUNT(*) as total, 
    SUM(CASE WHEN worker_name IS NULL OR worker_name='' OR worker_name='Worker' THEN 1 ELSE 0 END) as nameless_count,
    SUM(CASE WHEN worker_name IS NOT NULL AND worker_name!='' AND worker_name!='Worker' THEN 1 ELSE 0 END) as named_count
  FROM support_conversations;"`);
  console.log(stats.stdout);

  ssh.dispose();
}

main().catch(console.error);
