const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });

  const script = `
    const { NestFactory } = require('@nestjs/core');
    const { AppModule } = require('./dist/apps/api/app.module.js');
    const { NotificationEngineService } = require('./dist/notification-engine/notification.service.js');
    const { NotificationRepository } = require('./dist/shared/database/repositories/notification.repository.js');

    async function test() {
      const app = await NestFactory.createApplicationContext(AppModule);
      const notifService = app.get(NotificationEngineService);
      const notifRepo = app.get(NotificationRepository);

      console.log('Testing sendNotification for TASK_APPROVED to sufieditz@gmail.com (kQzd3bZD7pgA908xGE6NoGogetB3)...');
      await notifService.sendNotification(
        'kQzd3bZD7pgA908xGE6NoGogetB3',
        'Test: Your task submission has been approved successfully! ₹10 credited.',
        'TASK_APPROVED',
        { taskId: 'test-task-123', submissionId: 'test-sub-123', amount: 10 }
      );

      console.log('\\nTesting sendNotification for PAYOUT_COMPLETED to sufieditz@gmail.com...');
      await notifService.sendNotification(
        'sufieditz@gmail.com',
        'Test: Payout of ₹100.00 has been successfully transferred to your bank account! (Ref: TXN_TEST_999)',
        'PAYOUT_COMPLETED',
        { withdrawalId: 'test-with-123', amount: 100, transactionId: 'TXN_TEST_999' }
      );

      console.log('\\nChecking notifications in MySQL for sufieditz / kQzd3bZD7pgA908xGE6NoGogetB3...');
      const notifs = await notifRepo.findByUserId('kQzd3bZD7pgA908xGE6NoGogetB3');
      console.log('MySQL Notifications found:', notifs.length);
      for (const n of notifs.slice(0, 3)) {
        console.log(' - Title:', n.title, '| Type:', n.type, '| Message:', n.message);
      }

      await app.close();
      process.exit(0);
    }

    test().catch(e => { console.error(e); process.exit(1); });
  `;

  const res = await ssh.execCommand(`node -e "${script.replace(/\n/g, ' ')}"`, { cwd: '/opt/task-engine' });
  console.log('STDOUT:\n', res.stdout);
  if (res.stderr) console.error('STDERR:\n', res.stderr);

  process.exit(0);
}

run().catch(console.error);
