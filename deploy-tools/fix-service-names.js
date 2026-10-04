const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function main() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  console.log('Connected to VPS SSH.');

  const updates = [
    // 1. YouTube Relevant Comments
    `UPDATE service_catalog SET 
      name = 'YouTube Relevant Comments',
      description = 'Authentic contextual comments on your YouTube video to boost engagement, watch-time and algorithm reach.',
      service_type = 'comment',
      category = 'YouTube',
      ai_generator_enabled = 1,
      link_field_label = 'YouTube Video Link',
      link_field_placeholder = 'https://www.youtube.com/watch?v=... or https://youtu.be/...'
     WHERE code = 'YOUTUBE_COMMENT';`,

    // 2. Instagram Post & Reel Likes
    `UPDATE service_catalog SET 
      name = 'Instagram Post & Reel Likes',
      description = 'Instant genuine likes on posts and reels from real users to boost explore algorithm placement.',
      service_type = 'like',
      category = 'Instagram',
      ai_generator_enabled = 0,
      link_field_label = 'Instagram Post / Reel URL',
      link_field_placeholder = 'https://www.instagram.com/p/... or /reel/...'
     WHERE code = 'INSTAGRAM_LIKE';`,

    // 3. Instagram Engagement Combo
    `UPDATE service_catalog SET 
      name = 'Instagram Engagement Combo (Like + Comment)',
      description = 'All-in-one engagement bundle: Real users like post/reel and leave authentic AI-generated comments.',
      service_type = 'combo',
      category = 'Instagram',
      ai_generator_enabled = 1,
      link_field_label = 'Instagram Post / Reel URL',
      link_field_placeholder = 'https://www.instagram.com/p/... or /reel/...'
     WHERE code = 'INSTAGRAM_COMBO';`,

    // 4. Remove leftover test service if exists
    `DELETE FROM service_catalog WHERE code = 'TEST_1788885645568';`,
  ];

  for (const sql of updates) {
    const res = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "${sql.replace(/\n/g, ' ')}"`);
    if (res.stderr) console.error('SQL Error:', res.stderr);
  }

  console.log('\nUpdated service catalog:');
  const verify = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, code, name, category, service_type, ai_generator_enabled FROM service_catalog ORDER BY category, name;"`);
  console.log(verify.stdout);

  ssh.dispose();
}

main().catch(console.error);
