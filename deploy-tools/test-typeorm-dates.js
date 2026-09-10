const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });

    const testScript = `
const { DataSource } = require('/opt/task-engine/node_modules/typeorm');
const { Task } = require('/opt/task-engine/dist/shared/database/entities/task.entity');

async function test() {
  const ds = new DataSource({
    type: 'mysql',
    host: '127.0.0.1',
    port: 3306,
    username: 'taskapp',
    password: 'taskapp_password',
    database: 'task_platform',
    entities: [Task],
    synchronize: false,
  });

  await ds.initialize();
  const taskRepo = ds.getRepository(Task);

  const tasks = await taskRepo.find({
    order: { updatedAt: 'DESC' },
    take: 5
  });

  const now = new Date();
  console.log('Current Date (now):', now.toISOString(), 'Local:', now.toString());

  for (const t of tasks) {
    console.log('--- Task:', t.id, 'Status:', t.status, 'assignedTo:', t.assignedTo);
    console.log('  createdAt:', t.createdAt, typeof t.createdAt);
    console.log('  assignedAt:', t.assignedAt);
    console.log('  acceptedAt:', t.acceptedAt);
    console.log('  deadline:', t.deadline, typeof t.deadline);
    if (t.deadline) {
      const d = new Date(t.deadline);
      console.log('  deadline parsed:', d.toISOString(), 'd < now?', d < now);
    }
  }

  await ds.destroy();
}

test().catch(console.error);
`;

    await ssh.execCommand(`cat << 'EOF' > /tmp/test-typeorm-dates.js\n${testScript}\nEOF`);
    const res = await ssh.execCommand('node /tmp/test-typeorm-dates.js');
    console.log(res.stdout);
    if (res.stderr) console.log('STDERR:\n', res.stderr);

  } catch (e) {
    console.error(e);
  } finally {
    ssh.dispose();
  }
}
run();
