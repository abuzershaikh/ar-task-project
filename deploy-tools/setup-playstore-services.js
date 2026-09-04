const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function setupPlayStoreServices() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('Connected to Mumbai VPS via SSH!');

    const sql = `
USE \`task_platform\`;

-- 1. Clean up any existing Play Store entries
DELETE FROM \`service_pricing\` WHERE \`service_id\` IN ('play-review-001', 'play-rating-002');
DELETE FROM \`service_catalog\` WHERE \`id\` IN ('play-review-001', 'play-rating-002') OR \`code\` IN ('PLAYSTORE_REVIEW', 'PLAYSTORE_RATING', 'GOOGLE_PLAY_REVIEW');

-- 2. Seed Play Store 5-Star Rating & Review (AI Enabled)
INSERT INTO \`service_catalog\` (
    \`id\`, \`code\`, \`name\`, \`description\`, \`category\`, \`service_type\`,
    \`is_active\`, \`version\`, \`review_mode\`, \`worker_limit\`, \`min_accept_hours\`, \`max_accept_hours\`,
    \`min_complete_hours\`, \`max_complete_hours\`, \`watchtime_seconds\`, \`ai_generator_enabled\`,
    \`ai_generator_config\`, \`link_field_label\`, \`link_field_placeholder\`, \`text_field_label\`, \`text_field_placeholder\`,
    \`admin_instructions\`, \`created_at\`, \`updated_at\`
) VALUES (
    'play-review-001', 'PLAYSTORE_REVIEW', 'Play Store 5-Star Rating & Review',
    'Download app, give authentic 5-Star Rating and post custom AI review on Google Play Store.',
    'Google Play Store', 'review',
    1, 1, 'buyer', 1, 24, 72, 48, 168, 30, 1,
    '{"enabled":true,"generator_type":"playstore_review","language":"English","tone":"natural","uniqueness":true}',
    'Play Store App Link / Package ID', 'https://play.google.com/store/apps/details?id=...',
    'App Review Focus / Key Features', 'e.g. smooth UI, fast performance, highly recommended',
    '1. Open Google Play Store link\\n2. Download or open app & test for 30s\\n3. Give 5-Star Rating (⭐⭐⭐⭐⭐)\\n4. Copy assigned authentic review and submit\\n5. Upload screenshot proof showing rating & review posted',
    NOW(), NOW()
);

INSERT INTO \`service_pricing\` (
    \`id\`, \`service_id\`, \`buyer_unit_price\`, \`margin_type\`, \`margin_value\`, \`worker_reward\`,
    \`currency\`, \`version\`, \`is_active\`, \`created_at\`, \`updated_at\`
) VALUES (
    'play-price-review-001', 'play-review-001', 8.00, 'FIXED', 2.50, 5.50, 'INR', 1, 1, NOW(), NOW()
);

-- 3. Seed Play Store 5-Star Rating (Only) (AI Disabled)
INSERT INTO \`service_catalog\` (
    \`id\`, \`code\`, \`name\`, \`description\`, \`category\`, \`service_type\`,
    \`is_active\`, \`version\`, \`review_mode\`, \`worker_limit\`, \`min_accept_hours\`, \`max_accept_hours\`,
    \`min_complete_hours\`, \`max_complete_hours\`, \`watchtime_seconds\`, \`ai_generator_enabled\`,
    \`ai_generator_config\`, \`link_field_label\`, \`link_field_placeholder\`,
    \`admin_instructions\`, \`created_at\`, \`updated_at\`
) VALUES (
    'play-rating-002', 'PLAYSTORE_RATING', 'Play Store 5-Star Rating (Only)',
    'Give genuine 5-Star Rating to the target app on Google Play Store.',
    'Google Play Store', 'rating',
    1, 1, 'buyer', 1, 24, 72, 48, 168, 0, 0,
    '{"enabled":false,"generator_type":"none"}',
    'Play Store App Link / Package ID', 'https://play.google.com/store/apps/details?id=...',
    '1. Open Google Play Store link\\n2. Give 5-Star Rating (⭐⭐⭐⭐⭐)\\n3. Upload screenshot proof of 5-star rating',
    NOW(), NOW()
);

INSERT INTO \`service_pricing\` (
    \`id\`, \`service_id\`, \`buyer_unit_price\`, \`margin_type\`, \`margin_value\`, \`worker_reward\`,
    \`currency\`, \`version\`, \`is_active\`, \`created_at\`, \`updated_at\`
) VALUES (
    'play-price-rating-002', 'play-rating-002', 4.00, 'FIXED', 1.00, 3.00, 'INR', 1, 1, NOW(), NOW()
);
`;

    await ssh.execCommand(`cat << 'EOF' > /opt/task-engine/setup_playstore.sql\n${sql}\nEOF`);
    const sqlRes = await ssh.execCommand('mysql < /opt/task-engine/setup_playstore.sql');
    console.log('Database Setup Result:', sqlRes.stdout || 'Play Store services applied successfully!');
    if (sqlRes.stderr) console.error('Stderr:', sqlRes.stderr);

    const checkRes = await ssh.execCommand(`mysql -e "SELECT id, code, name, category, ai_generator_enabled FROM task_platform.service_catalog;"`);
    console.log('\n--- Active Service Catalog in MySQL ---');
    console.log(checkRes.stdout);

    const pricingRes = await ssh.execCommand(`mysql -e "SELECT id, service_id, buyer_unit_price, margin_value, worker_reward FROM task_platform.service_pricing;"`);
    console.log('\n--- Active Pricing in MySQL ---');
    console.log(pricingRes.stdout);

  } catch (err) {
    console.error('Error during setup:', err);
  } finally {
    ssh.dispose();
  }
}

setupPlayStoreServices();
