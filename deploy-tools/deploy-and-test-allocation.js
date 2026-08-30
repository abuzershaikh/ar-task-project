const { NodeSSH } = require('node-ssh');
const path = require('path');
const fs = require('fs');

const ssh = new NodeSSH();

async function deployAndTest() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('--- 1. Uploading updated backend files to VPS ---');
    const localDir = path.resolve(__dirname, '..', 'Task engine');
    
    // Upload task-query.service.ts
    await ssh.putFile(
      path.join(localDir, 'task-engine', 'queries', 'task-query.service.ts'),
      '/opt/task-engine/task-engine/queries/task-query.service.ts'
    );
    console.log('✓ Uploaded task-query.service.ts');

    // Upload task-command.service.ts
    await ssh.putFile(
      path.join(localDir, 'task-engine', 'handlers', 'task-command.service.ts'),
      '/opt/task-engine/task-engine/handlers/task-command.service.ts'
    );
    console.log('✓ Uploaded task-command.service.ts');

    console.log('\n--- 2. Compiling backend on VPS (npm run build) ---');
    const buildRes = await ssh.execCommand('npm run build', { cwd: '/opt/task-engine' });
    console.log(buildRes.stdout);
    if (buildRes.stderr && !buildRes.stdout) console.error(buildRes.stderr);

    console.log('\n--- 3. Restarting PM2 task-engine-api ---');
    const pm2Res = await ssh.execCommand('pm2 restart task-engine-api', { cwd: '/opt/task-engine' });
    console.log(pm2Res.stdout);

    console.log('\n--- 4. Running Multi-Worker Simulation Test ---');
    // Test: Create a mock campaign with 3 units in DB
    const simScript = `
const { DataSource } = require('typeorm');
async function test() {
  const mysql = require('mysql2/promise');
  const conn = await mysql.createConnection({
    host: 'localhost',
    user: 'taskapp',
    password: 'taskapp_password',
    database: 'task_platform'
  });

  // Clean tables
  await conn.query('DELETE FROM tasks');
  await conn.query('DELETE FROM orders');
  await conn.query('DELETE FROM users WHERE email LIKE "sim_%@test.com"');

  // Insert Buyer
  await conn.query("INSERT INTO users (id, email, full_name, role, status, password) VALUES ('sim_buyer_1', 'sim_buyer@test.com', 'Sim Buyer', 'BUYER', 'ACTIVE', 'pass')");

  // Insert Order with 3 units
  const orderId = 'sim_order_100';
  await conn.query("INSERT INTO orders (id, buyer_id, service_code, quantity, unit_price, total_amount, status) VALUES ('" + orderId + "', 'sim_buyer_1', 'YOUTUBE_COMMENT', 3, 5, 15, 'ACTIVE')");

  // Insert 3 Task Units for this 1 campaign
  for (let i = 1; i <= 3; i++) {
    await conn.query("INSERT INTO tasks (id, order_id, campaign_id, task_type, reward_amount, status, requirements) VALUES ('sim_task_" + i + "', '" + orderId + "', '" + orderId + "', 'YOUTUBE_COMMENT', 2.00, 'active', JSON_OBJECT('unit', " + i + ", 'title', 'Unit " + i + "'))");
  }

  // Create 3 Workers
  await conn.query("INSERT INTO users (id, email, full_name, role, status, password) VALUES ('sim_worker_1', 'sim_w1@test.com', 'Worker 1', 'WORKER', 'ACTIVE', 'pass')");
  await conn.query("INSERT INTO users (id, email, full_name, role, status, password) VALUES ('sim_worker_2', 'sim_w2@test.com', 'Worker 2', 'WORKER', 'ACTIVE', 'pass')");
  await conn.query("INSERT INTO users (id, email, full_name, role, status, password) VALUES ('sim_worker_3', 'sim_w3@test.com', 'Worker 3', 'WORKER', 'ACTIVE', 'pass')");

  console.log('Inserted 1 Order with 3 Task units.');
  await conn.end();
}
test();
    `;

    await ssh.execCommand(`node -e "${simScript.replace(/\n/g, ' ')}"`, { cwd: '/opt/task-engine' });

    // 1. Worker 1 checks available tasks -> Should see EXACTLY 1 task unit (not 3!)
    const w1Check = await ssh.execCommand('curl -s -H "x-user-email: sim_w1@test.com" -H "x-user-id: sim_worker_1" -H "x-user-role: WORKER" http://127.0.0.1:3000/api/v1/worker/tasks/available');
    const w1Data = JSON.parse(w1Check.stdout);
    console.log('Worker 1 available tasks count:', w1Data.tasks.length, '(Expected: 1 task)');

    // 2. Worker 1 accepts the task
    const acceptedTaskId = w1Data.tasks[0].id;
    console.log('Worker 1 accepting task:', acceptedTaskId);
    const acceptRes = await ssh.execCommand(`curl -s -X POST -H "x-user-email: sim_w1@test.com" -H "x-user-id: sim_worker_1" -H "x-user-role: WORKER" http://127.0.0.1:3000/api/v1/worker/tasks/${acceptedTaskId}/accept`);
    console.log('Worker 1 accept response:', acceptRes.stdout);

    // 3. Worker 1 refreshes available tasks -> Should see 0 tasks (already took their 1 task from this campaign!)
    const w1AfterAccept = await ssh.execCommand('curl -s -H "x-user-email: sim_w1@test.com" -H "x-user-id: sim_worker_1" -H "x-user-role: WORKER" http://127.0.0.1:3000/api/v1/worker/tasks/available');
    const w1AfterData = JSON.parse(w1AfterAccept.stdout);
    console.log('Worker 1 available tasks after accept:', w1AfterData.tasks.length, '(Expected: 0 tasks)');

    // 4. Worker 2 (second worker) checks available tasks -> Should see EXACTLY 1 of the remaining 2 units
    const w2Check = await ssh.execCommand('curl -s -H "x-user-email: sim_w2@test.com" -H "x-user-id: sim_worker_2" -H "x-user-role: WORKER" http://127.0.0.1:3000/api/v1/worker/tasks/available');
    const w2Data = JSON.parse(w2Check.stdout);
    console.log('Worker 2 available tasks count:', w2Data.tasks.length, '(Expected: 1 task)');

    // 5. Worker 3 (NEW worker) checks available tasks -> Should see EXACTLY 1 of the remaining units
    const w3Check = await ssh.execCommand('curl -s -H "x-user-email: sim_w3@test.com" -H "x-user-id: sim_worker_3" -H "x-user-role: WORKER" http://127.0.0.1:3000/api/v1/worker/tasks/available');
    const w3Data = JSON.parse(w3Check.stdout);
    console.log('Worker 3 (New Worker) available tasks count:', w3Data.tasks.length, '(Expected: 1 task)');

    // Clean simulation data after test
    await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "
      DELETE FROM task_assignments WHERE campaign_id = 'sim_order_100';
      DELETE FROM campaign_worker_participations WHERE campaign_id = 'sim_order_100';
      DELETE FROM tasks WHERE order_id = 'sim_order_100';
      DELETE FROM orders WHERE id = 'sim_order_100';
      DELETE FROM users WHERE email LIKE 'sim_%@test.com';
    "`);
    console.log('\n✅ Cleaned simulation data.');

  } catch (err) {
    console.error('Error during deployment & verification:', err);
  } finally {
    ssh.dispose();
  }
}

deployAndTest();
