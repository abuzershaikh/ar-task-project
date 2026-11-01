const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  const script = `
const { NestFactory } = require('@nestjs/core');
const { AppModule } = require('/opt/task-engine/dist/apps/api/app.module.js');
const { OrderActivatedListener } = require('/opt/task-engine/dist/shared/services/order-activated.listener.js');

async function trigger() {
  const app = await NestFactory.createApplicationContext(AppModule, { logger: ['log', 'error', 'warn'] });
  const listener = app.get(OrderActivatedListener);

  const payload = {
    orderId: '83e113c4-505f-4d6a-86f6-a41470cd91ae',
    buyerId: '98d5c4b6-e41c-43f1-bfa0-5c66b533f5d5',
    serviceCode: 'GOOGLE_BUSINESS_RATING',
    totalTasksRequired: 5,
    workerRewardSnapshot: 15,
    activatedAt: new Date(),
  };

  console.log('Invoking handleOrderActivated for Order 83e113c4...');
  await listener.handleOrderActivated(payload);
  console.log('Successfully completed handleOrderActivated for Order 83e113c4!');
  await app.close();
}

trigger().catch(console.error);
`;

  await ssh.execCommand("cat << 'EOF' > /tmp/trigger_listener_2.js\n" + script + "\nEOF");
  const res = await ssh.execCommand('NODE_PATH=/opt/task-engine/node_modules node /tmp/trigger_listener_2.js', { cwd: '/opt/task-engine' });
  console.log(res.stdout);
  ssh.dispose();
}

run().catch(console.error);
