const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 15000,
  });

  console.log('--- Checking available tasks via NestJS service on VPS ---');
  const remoteScript = `
const { NestFactory } = require('@nestjs/core');
const { AppModule } = require('./dist/apps/api/app.module');
const { TaskQueryService } = require('./dist/task-engine/queries/task-query.service');

async function test() {
  const app = await NestFactory.createApplicationContext(AppModule, { logger: false });
  const service = app.get(TaskQueryService);
  const tasks = await service.getAvailableTasks('sufieditz@gmail.com', 'sufieditz@gmail.com');
  console.log('Total available tasks for sufieditz:', tasks.length);
  tasks.forEach(t => {
    console.log('Task:', t.id, 'type:', t.taskType, 'order:', t.orderId, 'status:', t.status);
  });
  await app.close();
}
test().catch(console.error);
  `.trim();

  await ssh.execCommand(`cat << 'EOF' > /tmp/test-avail.js\n${remoteScript}\nEOF`);
  const res = await ssh.execCommand('node /tmp/test-avail.js', { cwd: '/opt/task-engine' });
  console.log(res.stdout);
  console.log(res.stderr);

  process.exit(0);
}

run().catch(console.error);
