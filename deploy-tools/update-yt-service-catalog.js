const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function updateCatalog() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('Connected to VPS. Updating service_catalog...');

    const queries = [
      "UPDATE service_catalog SET name = 'YouTube: Watch & Like Video', description = 'Real users watch your video (up to 2 min mandatory view) before liking. Increases Average View Duration and protects your likes from YouTube spam drop.' WHERE code = 'YOUTUBE_LIKE';",
      "UPDATE service_catalog SET name = 'YouTube: Watch & Subscribe Channel', description = 'Permanent real channel subscribers. Workers watch video (up to 2 min mandatory view) before subscribing, completely bypassing YouTube anti-spam subscriber filters.' WHERE code = 'YOUTUBE_SUBSCRIBE';",
      "UPDATE service_catalog SET name = 'YouTube: Watch & Relevant Comments', description = 'Real users watch video (up to 2 min mandatory view) and leave thoughtful, relevant comments. High-retention viewing signals strong algorithmic rank to YouTube.' WHERE code = 'YOUTUBE_COMMENT';",
      "UPDATE service_catalog SET name = 'YouTube Growth Combo (Watch, Like, Sub & Comment)', description = 'The ultimate 4-in-1 viral growth bundle: Full/custom video watch time + thumbs-up Like + channel Subscribe + contextual positive Comment from genuine real users.' WHERE code = 'YOUTUBE_COMBO';",
      "UPDATE service_catalog SET category = 'Google Maps' WHERE id = 'gmb-review-001';",
      "UPDATE service_catalog SET category = 'Play Store' WHERE id = 'play-review-001';",
    ];

    for (const q of queries) {
      const res = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "${q}"`);
      if (res.stderr) console.error('Error on query:', q, res.stderr);
    }

    console.log('Updated! Querying current service_catalog...');
    const verify = await ssh.execCommand(
      `mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, code, name, category, watchtime_seconds, description FROM service_catalog WHERE code LIKE '%YOUTUBE%' OR id IN ('gmb-review-001', 'play-review-001');"`
    );
    console.log(verify.stdout);

    // Restart pm2 task-engine-api to clear any cached catalog in Redis/memory if any
    console.log('Restarting task-engine-api...');
    await ssh.execCommand('pm2 restart 1');
    console.log('Done!');

    ssh.dispose();
  } catch (err) {
    console.error(err);
    ssh.dispose();
  }
}

updateCatalog();
