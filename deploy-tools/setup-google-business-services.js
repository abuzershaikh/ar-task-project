const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function setupGoogleBusinessServices() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('Connected to Mumbai VPS via SSH!');

    const sql = `
USE \`task_platform\`;

-- 1. Clean up any existing Google Business entries
DELETE FROM \`service_pricing\` WHERE \`service_id\` IN ('gmb-review-001', 'gmb-rating-002');
DELETE FROM \`service_catalog\` WHERE \`id\` IN ('gmb-review-001', 'gmb-rating-002') OR \`code\` IN ('GOOGLE_BUSINESS_REVIEW', 'GOOGLE_BUSINESS_RATING', 'GOOGLE_MAPS_REVIEW', 'GOOGLE_MAPS_RATING');

-- 2. Seed Google Business 5-Star Rating & Review (AI Enabled)
INSERT INTO \`service_catalog\` (
    \`id\`, \`code\`, \`name\`, \`description\`, \`category\`, \`service_type\`,
    \`is_active\`, \`version\`, \`review_mode\`, \`worker_limit\`, \`min_accept_hours\`, \`max_accept_hours\`,
    \`min_complete_hours\`, \`max_complete_hours\`, \`watchtime_seconds\`, \`ai_generator_enabled\`,
    \`ai_generator_config\`, \`link_field_label\`, \`link_field_placeholder\`, \`text_field_label\`, \`text_field_placeholder\`,
    \`admin_instructions\`, \`created_at\`, \`updated_at\`
) VALUES (
    'gmb-review-001', 'GOOGLE_BUSINESS_REVIEW', 'Google Business 5-Star Rating & Review',
    'Open business listing on Google Maps, give genuine 5-Star Rating and post custom authentic AI review.',
    'Google Business', 'review',
    1, 1, 'buyer', 1, 24, 72, 48, 168, 30, 1,
    '{"enabled":true,"generator_type":"google_business_review","language":"English","tone":"natural","uniqueness":true}',
    'Google Maps / Business Link or Search Query', 'https://maps.app.goo.gl/... or Business Name, City',
    'Review Focus / Business Highlights', 'e.g. delicious food, polite staff, fast delivery, clean ambiance',
    '1. Open the Google Maps link to view the business\\n2. Give 5-Star Rating (⭐⭐⭐⭐⭐)\\n3. Copy assigned authentic review and post it\\n4. Upload screenshot proof showing your review posted on Google Maps',
    NOW(), NOW()
);

INSERT INTO \`service_pricing\` (
    \`id\`, \`service_id\`, \`buyer_unit_price\`, \`margin_type\`, \`margin_value\`, \`worker_reward\`,
    \`currency\`, \`version\`, \`is_active\`, \`created_at\`, \`updated_at\`
) VALUES (
    'gmb-price-review-001', 'gmb-review-001', 10.00, 'FIXED', 3.00, 7.00, 'INR', 1, 1, NOW(), NOW()
);

-- 3. Seed Google Business 5-Star Rating (Only) (AI Disabled)
INSERT INTO \`service_catalog\` (
    \`id\`, \`code\`, \`name\`, \`description\`, \`category\`, \`service_type\`,
    \`is_active\`, \`version\`, \`review_mode\`, \`worker_limit\`, \`min_accept_hours\`, \`max_accept_hours\`,
    \`min_complete_hours\`, \`max_complete_hours\`, \`watchtime_seconds\`, \`ai_generator_enabled\`,
    \`ai_generator_config\`, \`link_field_label\`, \`link_field_placeholder\`,
    \`admin_instructions\`, \`created_at\`, \`updated_at\`
) VALUES (
    'gmb-rating-002', 'GOOGLE_BUSINESS_RATING', 'Google Business 5-Star Rating (Only)',
    'Open business listing on Google Maps and give genuine 5-Star Rating.',
    'Google Business', 'rating',
    1, 1, 'buyer', 1, 24, 72, 48, 168, 0, 0,
    '{"enabled":false,"generator_type":"none"}',
    'Google Maps / Business Link or Search Query', 'https://maps.app.goo.gl/... or Business Name, City',
    '1. Open the Google Maps link to view the business\\n2. Give 5-Star Rating (⭐⭐⭐⭐⭐)\\n3. Upload screenshot proof of 5-star rating given',
    NOW(), NOW()
);

INSERT INTO \`service_pricing\` (
    \`id\`, \`service_id\`, \`buyer_unit_price\`, \`margin_type\`, \`margin_value\`, \`worker_reward\`,
    \`currency\`, \`version\`, \`is_active\`, \`created_at\`, \`updated_at\`
) VALUES (
    'gmb-price-rating-002', 'gmb-rating-002', 5.00, 'FIXED', 1.50, 3.50, 'INR', 1, 1, NOW(), NOW()
);
`;

    await ssh.execCommand(`cat << 'EOF' > /opt/task-engine/setup_google_business.sql\n${sql}\nEOF`);
    const sqlRes = await ssh.execCommand('mysql < /opt/task-engine/setup_google_business.sql');
    console.log('Database Setup Result:', sqlRes.stdout || 'Google Business services applied successfully!');
    if (sqlRes.stderr) console.error('Stderr:', sqlRes.stderr);

    const checkRes = await ssh.execCommand(`mysql -e "SELECT id, code, name, category, service_type, ai_generator_enabled FROM task_platform.service_catalog;"`);
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

setupGoogleBusinessServices();
