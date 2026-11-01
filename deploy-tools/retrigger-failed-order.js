const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  const script = `
const { NestFactory } = require('@nestjs/core');
const { AppModule } = require('/opt/task-engine/dist/apps/api/app.module.js');
const { OrderActivatedListener } = require('/opt/task-engine/dist/shared/services/order-activated.listener.js');

async function trigger() {
  console.log('Creating standalone Nest application context...');
  const app = await NestFactory.createApplicationContext(AppModule, { logger: ['log', 'error', 'warn'] });
  const listener = app.get(OrderActivatedListener);

  const payload = {
    orderId: '302a200e-9a66-4846-a24c-15fb5b05b771',
    buyerId: '98d5c4b6-e41c-43f1-bfa0-5c66b533f5d5',
    serviceCode: 'GOOGLE_BUSINESS_RATING',
    totalTasksRequired: 5,
    workerRewardSnapshot: 15,
    activatedAt: new Date(),
  };

  console.log('Invoking handleOrderActivated for Order:', payload.orderId);
  await listener.handleOrderActivated(payload);
  console.log('Successfully completed handleOrderActivated!');
  await app.close();
}

trigger().catch(console.error);
`;

  await ssh.execCommand("cat << 'EOF' > /tmp/trigger_listener.js\n" + script + "\nEOF");
  console.log('Executing /tmp/trigger_listener.js on VPS...');
  const res = await ssh.execCommand('NODE_PATH=/opt/task-engine/node_modules node /tmp/trigger_listener.js', { cwd: '/opt/task-engine' });
  console.log(res.stdout);
  if (res.stderr) console.error('STDERR:', res.stderr);
  ssh.dispose();
}

run().catch(console.error);
