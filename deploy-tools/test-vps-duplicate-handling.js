const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function runTest() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    const script = `
      const { findDuplicateCommentMatches, compareCommentSimilarity, normalizedComment } = require('/opt/task-engine/dist/shared/ai-generator/comment-duplicate-detector');
      
      console.log('====================================================');
      console.log(' VPS DUPLICATE COMMENT DETECTOR VALIDATION REPORT');
      console.log('====================================================');

      // Test 1: Exact Duplicates (different cases and punctuations)
      const test1_c1 = "Awesome tutorial, thanks for sharing!";
      const test1_c2 = "awesome TUTORIAL thanks for sharing";
      const res1 = compareCommentSimilarity(test1_c1, test1_c2);
      console.log('\\n[TEST 1] Exact Match (Case & Punctuation Insensitive):');
      console.log(' - Comment 1:', test1_c1);
      console.log(' - Comment 2:', test1_c2);
      console.log(' - ExactMatch detected:', res1.exactMatch, 'Similarity:', res1.similarity);
      if (!res1.exactMatch) throw new Error('Test 1 failed');

      // Test 2: 80% Word Overlap (Threshold Trigger)
      const test2_c1 = "This is a great video that explains everything clearly to beginners";
      const test2_c2 = "This is a great video that explains everything clearly to students"; // 9 out of 10 words match (90%)
      const res2 = compareCommentSimilarity(test2_c1, test2_c2);
      console.log('\\n[TEST 2] 80%+ Word Overlap Detection:');
      console.log(' - Comment 1:', test2_c1);
      console.log(' - Comment 2:', test2_c2);
      console.log(' - Overlap Similarity:', (res2.similarity * 100).toFixed(1) + '%');
      if (res2.similarity < 0.8) throw new Error('Test 2 failed');

      // Test 3: Multiple comments batch with mixed duplicates
      const batch = [
        "First original unique comment about coding",
        "Second original unique comment about design and color palette",
        "first original unique comment about coding", // exact dupe of 0
        "Third original unique comment about testing",
        "Second original unique comment about design and color schemes" // 7 out of 8 words match = 87.5% (>80%)
      ];
      console.log('\\n[TEST 3] Batch of 5 comments with 2 duplicates:');
      const dupes = findDuplicateCommentMatches(batch);
      console.log(' - Detected duplicates count:', dupes.length);
      dupes.forEach((d, idx) => {
        console.log(\`   Duplicate #\${idx + 1}: Index \${d.duplicateIndex} ("\${batch[d.duplicateIndex]}") matches Index \${d.matchedIndex} (similarity: \${(d.similarity.similarity * 100).toFixed(1)}%)\`);
      });

      if (dupes.length !== 2 || dupes[0].duplicateIndex !== 2 || dupes[1].duplicateIndex !== 4) {
        throw new Error('Test 3 failed: wrong duplicate indexes identified');
      }

      // Test 4: Completely distinct comments (no false positives)
      const distinctBatch = [
        "Loved the clear explanation of Flutter state management",
        "Can you also make a tutorial on Node.js clustering?",
        "Subscribed! Really looking forward to your next upload.",
        "The audio quality and video pacing were super professional."
      ];
      console.log('\\n[TEST 4] Batch of 4 distinct comments (False Positive Check):');
      const noDupes = findDuplicateCommentMatches(distinctBatch);
      console.log(' - Detected duplicates count:', noDupes.length);
      if (noDupes.length !== 0) throw new Error('Test 4 failed: false positives found');

      console.log('\\n====================================================');
      console.log(' 100% VERIFIED: ALL DUPLICATE DETECTOR TESTS PASSED!');
      console.log('====================================================');
    `;

    await ssh.execCommand(`cat << 'EOF' > /tmp/validate-dupes.js\n${script}\nEOF`);
    const res = await ssh.execCommand('node /tmp/validate-dupes.js', { cwd: '/opt/task-engine' });
    console.log(res.stdout);
    if (res.stderr) console.error('STDERR:', res.stderr);
    await ssh.execCommand('rm -f /tmp/validate-dupes.js');

  } catch (err) {
    console.error('Error:', err);
  } finally {
    ssh.dispose();
  }
}

runTest();
