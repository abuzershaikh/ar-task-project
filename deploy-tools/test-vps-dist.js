const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  const remoteScript = `
const { compareCommentSimilarity, findDuplicateCommentMatches, normalizedComment } = require('/opt/task-engine/dist/shared/ai-generator/comment-duplicate-detector');
const { AiGeneratorService } = require('/opt/task-engine/dist/shared/ai-generator/ai-generator.service');

console.log('--- 1. Normalized String Test ---');
const norm = normalizedComment('  Great Video!!! Check this out... :) ');
console.log('Normalized output:', norm);

console.log('\\n--- 2. Exact Duplicate Test (Case/Punctuation Insensitive) ---');
const c1 = 'This video was very helpful, thank you!';
const c2 = 'this VIDEO was very helpful thank you';
const exactComp = compareCommentSimilarity(c1, c2);
console.log('Exact match result:', exactComp);
if (!exactComp.exactMatch) throw new Error('Exact match failed');

console.log('\\n--- 3. 80% Word Similarity Test ---');
const batch = [
  'one two three four five six seven eight nine ten',
  'one two three four five six seven eight eleven twelve',
  'completely different comment here that should pass'
];
const dupes = findDuplicateCommentMatches(batch);
console.log('Duplicates found count:', dupes.length);
console.log('Duplicate details:', JSON.stringify(dupes, null, 2));
if (dupes.length !== 1 || dupes[0].duplicateIndex !== 1) {
  throw new Error('80% duplicate detection failed');
}

console.log('\\n--- 4. Distinct Comments Test (Below 80%) ---');
const distinct = [
  'Great tutorial on flutter development',
  'Loved the explanation of state management in flutter',
  'Very clear guide for beginners'
];
const noDupes = findDuplicateCommentMatches(distinct);
console.log('Duplicates in distinct batch:', noDupes.length);
if (noDupes.length !== 0) throw new Error('Distinct comments wrongly flagged');

console.log('\\n--- 5. AiGeneratorService Class Loaded in VPS dist ---');
console.log('AiGeneratorService type:', typeof AiGeneratorService);

console.log('\\n>>> 100% SUCCESS: All VPS Dist Compiled Code Tests Passed! <<<');
`;

  await ssh.execCommand(`cat << 'EOF' > /tmp/test-duplicate-vps.js\n${remoteScript}\nEOF`);
  const res = await ssh.execCommand('node /tmp/test-duplicate-vps.js', { cwd: '/opt/task-engine' });
  console.log(res.stdout);
  if (res.stderr) console.error(res.stderr);
  await ssh.execCommand('rm -f /tmp/test-duplicate-vps.js');
  ssh.dispose();
}

run();
