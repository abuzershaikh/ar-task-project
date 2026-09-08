const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function updateCombos() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('✅ Connected to VPS via SSH!');

    // 1. Update Database for INSTAGRAM_COMBO and YOUTUBE_COMBO
    const sql = `
USE \\\`task_platform\\\`;

-- Update INSTAGRAM_COMBO to Like + Follow (NO COMMENTS, AI OFF)
UPDATE \\\`service_catalog\\\`
SET 
  \\\`name\\\` = 'Instagram Engagement Combo (Like + Follow)',
  \\\`description\\\` = 'Boost profile authority and post reach: Real users follow profile and like post/reel.',
  \\\`category\\\` = 'Instagram',
  \\\`service_type\\\` = 'combo',
  \\\`ai_generator_enabled\\\` = 0,
  \\\`ai_generator_config\\\` = '{"enabled":false,"actions":{"like":true,"follow":true,"comment":false}}',
  \\\`link_field_label\\\` = 'Instagram Profile or Post/Reel URL',
  \\\`link_field_placeholder\\\` = 'https://www.instagram.com/your_username or /p/...',
  \\\`admin_instructions\\\` = '1. Open Instagram link\\\\n2. Follow creator profile\\\\n3. Like latest post/reel\\\\n4. Upload screenshot proof',
  \\\`updated_at\\\` = NOW()
WHERE \\\`code\\\` = 'INSTAGRAM_COMBO';

-- Update pricing for INSTAGRAM_COMBO
UPDATE \\\`service_pricing\\\` sp
JOIN \\\`service_catalog\\\` sc ON sp.service_id = sc.id
SET 
  sp.buyer_unit_price = 2.50,
  sp.margin_value = 0.50,
  sp.worker_reward = 2.00,
  sp.updated_at = NOW()
WHERE sc.code = 'INSTAGRAM_COMBO';

-- Update YOUTUBE_COMBO to Watch + Like + Sub + Comment (AI ON)
UPDATE \\\`service_catalog\\\`
SET 
  \\\`name\\\` = 'YouTube Growth Combo (Watch + Like + Sub + Comment)',
  \\\`description\\\` = 'Complete viral package: Watch video, Like, Subscribe to channel, and post relevant AI comment.',
  \\\`category\\\` = 'YouTube',
  \\\`service_type\\\` = 'combo',
  \\\`ai_generator_enabled\\\` = 1,
  \\\`ai_generator_config\\\` = '{"enabled":true,"generator_type":"youtube_comment","language":"English","tone":"natural","uniqueness":true,"actions":{"like":true,"subscribe":true,"comment":true}}',
  \\\`link_field_label\\\` = 'YouTube Video URL',
  \\\`link_field_placeholder\\\` = 'https://www.youtube.com/watch?v=... or https://youtu.be/...',
  \\\`text_field_label\\\` = 'Video Topic / Comment Instructions',
  \\\`text_field_placeholder\\\` = 'e.g. loved the tutorial, very helpful!',
  \\\`watchtime_seconds\\\` = 60,
  \\\`updated_at\\\` = NOW()
WHERE \\\`code\\\` = 'YOUTUBE_COMBO';

-- Update pricing for YOUTUBE_COMBO
UPDATE \\\`service_pricing\\\` sp
JOIN \\\`service_catalog\\\` sc ON sp.service_id = sc.id
SET 
  sp.buyer_unit_price = 8.00,
  sp.margin_value = 2.00,
  sp.worker_reward = 6.00,
  sp.updated_at = NOW()
WHERE sc.code = 'YOUTUBE_COMBO';
`;

    console.log('1. Executing SQL update on MariaDB...');
    const dbRes = await ssh.execCommand(`mysql -e "${sql.replace(/\n/g, ' ')}"`);
    if (dbRes.stderr) {
      console.warn('DB stderr:', dbRes.stderr);
    } else {
      console.log('✅ Database updated successfully!');
    }

    // 2. Check where task-engine is hosted on the VPS
    console.log('\n2. Finding Task Engine location on VPS...');
    const pm2Details = await ssh.execCommand('pm2 jlist');
    const apps = JSON.parse(pm2Details.stdout || '[]');
    const taskApi = apps.find(a => a.name === 'task-engine-api');
    if (taskApi) {
      console.log(`Task API working dir: ${taskApi.pm2_env.pm_cwd}`);
      const cwd = taskApi.pm2_env.pm_cwd;

      console.log('\n3. Pulling latest Git changes in backend on VPS...');
      const pullRes = await ssh.execCommand(`cd "${cwd}" && git pull origin main`);
      console.log('Git pull output:\n' + (pullRes.stdout || pullRes.stderr));

      console.log('\n4. Building and restarting PM2...');
      const restartRes = await ssh.execCommand(`cd "${cwd}" && npm run build && pm2 restart task-engine-api`);
      console.log('PM2 restart output:\n' + (restartRes.stdout || restartRes.stderr));
    }

    console.log('\n5. Querying updated service catalog from API...');
    const catalogCheck = await ssh.execCommand('curl -s http://localhost:3000/api/v1/buyer/services');
    try {
      const cat = JSON.parse(catalogCheck.stdout);
      const insta = cat.services?.find(s => s.code === 'INSTAGRAM_COMBO');
      const yt = cat.services?.find(s => s.code === 'YOUTUBE_COMBO');
      console.log('  -> INSTAGRAM_COMBO:', insta ? `${insta.name} | ₹${insta.buyerUnitPrice} | aiEnabled: ${insta.aiGeneratorEnabled}` : 'Not found');
      console.log('  -> YOUTUBE_COMBO:  ', yt ? `${yt.name} | ₹${yt.buyerUnitPrice} | aiEnabled: ${yt.aiGeneratorEnabled}` : 'Not found');
    } catch (_) {
      console.log(catalogCheck.stdout.substring(0, 300));
    }

    console.log('\n=============================================');
    console.log('      VPS BACKEND VERIFICATION COMPLETE       ');
    console.log('=============================================');

  } catch (err) {
    console.error('Error during VPS update:', err);
  } finally {
    ssh.dispose();
  }
}

updateCombos();
