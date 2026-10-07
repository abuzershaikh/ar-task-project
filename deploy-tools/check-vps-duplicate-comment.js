const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function checkVPSDuplicateComment() {
  try {
    console.log('Connecting to VPS 65.20.77.112...');
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw'
    });
    console.log('Connected to VPS!');

    // 1. Check if files exist on VPS
    console.log('\n--- Checking file existence on VPS ---');
    const checkFiles = await ssh.execCommand(
      'ls -la shared/ai-generator/comment-duplicate-detector.ts shared/ai-generator/ai-generator.service.ts shared/services/order-activated.listener.ts',
      { cwd: '/opt/task-engine' }
    );
    console.log(checkFiles.stdout || checkFiles.stderr);

    // 2. Check git status on VPS
    console.log('\n--- Checking git status on VPS ---');
    const gitStatus = await ssh.execCommand('git status', { cwd: '/opt/task-engine' });
    console.log(gitStatus.stdout || gitStatus.stderr);

    // 3. Check git log on VPS
    console.log('\n--- Checking latest git commit on VPS ---');
    const gitLog = await ssh.execCommand('git log -n 3 --oneline', { cwd: '/opt/task-engine' });
    console.log(gitLog.stdout || gitLog.stderr);

    // 4. Check if dist has compiled files
    console.log('\n--- Checking dist compiled files on VPS ---');
    const distCheck = await ssh.execCommand(
      'ls -la dist/shared/ai-generator/comment-duplicate-detector.js dist/shared/ai-generator/ai-generator.service.js',
      { cwd: '/opt/task-engine' }
    );
    console.log(distCheck.stdout || distCheck.stderr);

    // 5. Test comment duplicate detector in node on VPS
    console.log('\n--- Running duplicate comment detector test on VPS Node ---');
    const nodeTest = await ssh.execCommand(`node -e "
      try {
        const { compareCommentSimilarity, findDuplicateCommentMatches } = require('./dist/shared/ai-generator/comment-duplicate-detector');
        
        console.log('Testing exact match detection:');
        const exact = compareCommentSimilarity('This video was very helpful, thank you!', 'this VIDEO was very helpful thank you');
        console.log('Exact match:', exact);

        console.log('Testing 80% word similarity detection:');
        const comments = [
          'one two three four five six seven eight nine ten',
          'one two three four five six seven eight eleven twelve',
          'completely different third comment here'
        ];
        const dupes = findDuplicateCommentMatches(comments);
        console.log('Duplicates detected:', dupes.length);
        console.log('Dupe details:', JSON.stringify(dupes, null, 2));

        if (dupes.length === 1 && dupes[0].duplicateIndex === 1 && exact.exactMatch) {
          console.log('>>> SUCCESS: comment-duplicate-detector is 100% WORKING on VPS dist! <<<');
        } else {
          console.error('>>> FAIL: unexpected detection results <<<');
        }
      } catch (e) {
        console.error('Error running test on VPS:', e.message);
      }
    "`, { cwd: '/opt/task-engine' });
    console.log(nodeTest.stdout);
    if (nodeTest.stderr) console.error('Node stderr:', nodeTest.stderr);

    // 6. Check PM2 status on VPS
    console.log('\n--- PM2 status on VPS ---');
    const pm2Status = await ssh.execCommand('pm2 list', { cwd: '/opt/task-engine' });
    console.log(pm2Status.stdout || pm2Status.stderr);

    ssh.dispose();
  } catch (err) {
    console.error('SSH Error:', err);
    ssh.dispose();
  }
}

checkVPSDuplicateComment();
