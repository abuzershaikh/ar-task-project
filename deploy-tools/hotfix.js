const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function hotfix() {
    await ssh.connect({
      host: '95.179.178.6',
      username: 'root',
      password: 'i_G72#y}(6gACDDU'
    });
    
    console.log('Uploading wallet & topup backend updates to Task engine on VPS...');
    const files = [
      ['d:/AR Task Project/Task engine/shared/database/entities/service-catalog.entity.ts', '/var/www/task-engine/Task engine/shared/database/entities/service-catalog.entity.ts'],
      ['d:/AR Task Project/Task engine/shared/modules/service-catalog/services/service-catalog.service.ts', '/var/www/task-engine/Task engine/shared/modules/service-catalog/services/service-catalog.service.ts'],
      ['d:/AR Task Project/Task engine/apps/api/controllers/admin/service-catalog.controller.ts', '/var/www/task-engine/Task engine/apps/api/controllers/admin/service-catalog.controller.ts'],
      ['d:/AR Task Project/Task engine/apps/api/controllers/buyer/service-catalog.controller.ts', '/var/www/task-engine/Task engine/apps/api/controllers/buyer/service-catalog.controller.ts'],
      ['d:/AR Task Project/Task engine/shared/services/order-activated.listener.ts', '/var/www/task-engine/Task engine/shared/services/order-activated.listener.ts'],
      ['d:/AR Task Project/Task engine/apps/api/controllers/buyer/order.controller.ts', '/var/www/task-engine/apps/api/controllers/buyer/order.controller.ts'],
      ['d:/AR Task Project/Task engine/apps/worker/worker.module.ts', '/var/www/task-engine/Task engine/apps/worker/worker.module.ts'],
      ['d:/AR Task Project/Task engine/apps/worker/worker.module.ts', '/var/www/task-engine/apps/worker/worker.module.ts'],
      ['d:/AR Task Project/Task engine/shared/database/entities/service-catalog.entity.ts', '/var/www/task-engine/shared/database/entities/service-catalog.entity.ts'],
      ['d:/AR Task Project/Task engine/shared/modules/service-catalog/services/service-catalog.service.ts', '/var/www/task-engine/shared/modules/service-catalog/services/service-catalog.service.ts'],
      ['d:/AR Task Project/Task engine/apps/api/controllers/admin/service-catalog.controller.ts', '/var/www/task-engine/apps/api/controllers/admin/service-catalog.controller.ts'],
      ['d:/AR Task Project/Task engine/apps/api/controllers/buyer/service-catalog.controller.ts', '/var/www/task-engine/apps/api/controllers/buyer/service-catalog.controller.ts'],
      ['d:/AR Task Project/Task engine/shared/services/order-activated.listener.ts', '/var/www/task-engine/shared/services/order-activated.listener.ts'],
      ['d:/AR Task Project/Task engine/apps/api/controllers/buyer/order.controller.ts', '/var/www/task-engine/shared/services/order.controller.ts'],
    ];

    for (const [src, dest] of files) {
      await ssh.putFile(src, dest);
      console.log(`Uploaded ${src} -> ${dest}`);
    }
    
    console.log('Building Task engine on VPS...');
    const build = await ssh.execCommand("cd '/var/www/task-engine/Task engine' && npm run build");
    console.log('Build output:', build.stdout);
    if(build.stderr) console.error('Build stderr:', build.stderr);
    
    console.log('Backfilling active order tasks in DB...');
    const backfillScript = `
      const mysql = require('mysql2/promise');
      const crypto = require('crypto');
      async function backfill() {
        const conn = await mysql.createConnection({
          host: 'localhost',
          user: 'root',
          password: 'i_G72#y}(6gACDDU',
          database: 'task_platform'
        });
        const [orders] = await conn.execute("SELECT id, title, task_type, total_tasks_required, reward_per_task, worker_reward_snapshot, requirements FROM orders WHERE status = 'ACTIVE'");
        for (const order of orders) {
          const [tasks] = await conn.execute("SELECT count(*) as count FROM tasks WHERE order_id = ?", [order.id]);
          const existingCount = tasks[0].count;
          const required = order.total_tasks_required || 1;
          if (existingCount < required) {
            console.log("Generating " + (required - existingCount) + " tasks for order " + order.id + " (" + order.title + ")");
            const reqs = typeof order.requirements === 'string' ? order.requirements : JSON.stringify(order.requirements || {});
            const reward = order.worker_reward_snapshot || order.reward_per_task || 5;
            for (let i = existingCount; i < required; i++) {
              const taskId = crypto.randomUUID();
              await conn.execute(
                "INSERT INTO tasks (id, order_id, campaign_id, task_type, status, reward_amount, requirements, created_at, updated_at) VALUES (?, ?, ?, ?, 'active', ?, ?, NOW(), NOW())",
                [taskId, order.id, order.id, order.task_type || 'DEFAULT', reward, reqs]
              );
            }
          }
        }
        // Reset any unworked tasks to active for open feed availability
        await conn.execute("UPDATE tasks SET status = 'active', assigned_to = NULL, assigned_at = NULL WHERE status = 'assigned' AND (submitted_at IS NULL) AND (started_at IS NULL)");
        await conn.end();
        console.log("Backfill & feed activation complete.");
      }
      backfill().catch(console.error);
    `;
    await ssh.execCommand(`node -e "${backfillScript.replace(/"/g, '\\"').replace(/\n/g, ' ')}"`);

    console.log('Restarting all PM2 processes...');
    const restart = await ssh.execCommand('pm2 restart all');
    console.log(restart.stdout);
    
    ssh.dispose();
    console.log('Hotfix deployment finished successfully!');
}
hotfix();

