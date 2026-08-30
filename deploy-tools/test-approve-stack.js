const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function testApproveWithNest() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });

    console.log('--- Running test script inside NestJS context ---');
    const testScript = `
const { NestFactory } = require('@nestjs/core');
const { AppModule } = require('./dist/apps/api/app.module');
const { ReviewEngineService } = require('./dist/review-engine/review.service');

async function test() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const reviewEngine = app.get(ReviewEngineService);
  try {
    console.log('Attempting reviewSubmission...');
    const res = await reviewEngine.reviewSubmission('39d7b123-0cf4-4f67-81a1-9a2e145c6311', {
      action: 'approved',
      reviewedBy: 'system',
      notes: 'Test Approval'
    });
    console.log('Review Result:', res);
  } catch (err) {
    console.error('CAUGHT ERROR IN APPROVE:');
    console.error(err);
    if (err.stack) console.error(err.stack);
  } finally {
    await app.close();
  }
}

test();
`;
    await ssh.execCommand(`cat << 'EOF' > /opt/task-engine/test-approve-stack.js\n${testScript}\nEOF`);
    const runRes = await ssh.execCommand('node test-approve-stack.js', { cwd: '/opt/task-engine' });
    console.log(runRes.stdout);
    if (runRes.stderr) console.error('STDERR:\n', runRes.stderr);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

testApproveWithNest();
