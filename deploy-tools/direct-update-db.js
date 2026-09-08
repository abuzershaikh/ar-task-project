const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 15000,
  });

  console.log('--- Current DB Rows for Combos ---');
  const checkSql = `mysql -u taskapp -ptaskapp_password task_platform -e "SELECT sc.code, sc.name, sc.service_type, sc.ai_generator_enabled, sp.buyer_unit_price, sp.worker_reward FROM service_catalog sc LEFT JOIN service_pricing sp ON sc.id = sp.service_id WHERE sc.code IN ('INSTAGRAM_COMBO', 'YOUTUBE_COMBO');"`;
  const res1 = await ssh.execCommand(checkSql);
  console.log(res1.stdout);

  console.log('--- Updating Combos in DB ---');
  const updateScript = `
UPDATE service_catalog
SET 
  name = 'Instagram Engagement Combo (Like + Follow)',
  description = 'Boost profile authority and post reach: Real users follow profile and like post/reel.',
  category = 'Instagram',
  service_type = 'combo',
  ai_generator_enabled = 0,
  ai_generator_config = '{"enabled":false,"actions":{"like":true,"follow":true,"comment":false}}',
  link_field_label = 'Instagram Profile or Post/Reel URL',
  link_field_placeholder = 'https://www.instagram.com/your_username or /p/...',
  admin_instructions = '1. Open Instagram link\\n2. Follow creator profile\\n3. Like latest post/reel\\n4. Upload screenshot proof',
  updated_at = NOW()
WHERE code = 'INSTAGRAM_COMBO';

UPDATE service_pricing sp
JOIN service_catalog sc ON sp.service_id = sc.id
SET 
  sp.buyer_unit_price = 2.50,
  sp.margin_value = 0.50,
  sp.worker_reward = 2.00,
  sp.updated_at = NOW()
WHERE sc.code = 'INSTAGRAM_COMBO';

UPDATE service_catalog
SET 
  name = 'YouTube Growth Combo (Watch + Like + Sub + Comment)',
  description = 'Complete viral package: Watch video, Like, Subscribe to channel, and post relevant AI comment.',
  category = 'YouTube',
  service_type = 'combo',
  ai_generator_enabled = 1,
  ai_generator_config = '{"enabled":true,"generator_type":"youtube_comment","language":"English","tone":"natural","uniqueness":true,"actions":{"like":true,"subscribe":true,"comment":true}}',
  link_field_label = 'YouTube Video URL',
  link_field_placeholder = 'https://www.youtube.com/watch?v=... or https://youtu.be/...',
  text_field_label = 'Video Topic / Comment Instructions',
  text_field_placeholder = 'e.g. loved the tutorial, very helpful!',
  watchtime_seconds = 60,
  updated_at = NOW()
WHERE code = 'YOUTUBE_COMBO';

UPDATE service_pricing sp
JOIN service_catalog sc ON sp.service_id = sc.id
SET 
  sp.buyer_unit_price = 8.00,
  sp.margin_value = 2.00,
  sp.worker_reward = 6.00,
  sp.updated_at = NOW()
WHERE sc.code = 'YOUTUBE_COMBO';
`;

  // Write sql to temp file on VPS and execute
  await ssh.execCommand(`cat << 'EOF' > /tmp/update_combos.sql\n${updateScript}\nEOF`);
  const execRes = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform < /tmp/update_combos.sql');
  console.log('Update result:\n', execRes.stdout, execRes.stderr);

  console.log('--- Verification after Update ---');
  const res2 = await ssh.execCommand(checkSql);
  console.log(res2.stdout);

  ssh.dispose();
}

run();
