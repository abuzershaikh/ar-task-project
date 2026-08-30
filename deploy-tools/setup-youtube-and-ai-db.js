const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function setupDatabase() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('Connected to Mumbai VPS via SSH!');

    const sql = `
USE \`task_platform\`;

-- 1. Enhance service_catalog with AI Generator columns and category
ALTER TABLE \`service_catalog\` ADD COLUMN IF NOT EXISTS \`category\` varchar(100) NOT NULL DEFAULT 'YouTube';
ALTER TABLE \`service_catalog\` ADD COLUMN IF NOT EXISTS \`service_type\` varchar(100) NOT NULL DEFAULT 'like';
ALTER TABLE \`service_catalog\` ADD COLUMN IF NOT EXISTS \`ai_generator_enabled\` boolean NOT NULL DEFAULT false;
ALTER TABLE \`service_catalog\` ADD COLUMN IF NOT EXISTS \`ai_generator_config\` json NULL;

-- 2. Create order_units table for 1 Order = N Units architecture
CREATE TABLE IF NOT EXISTS \`order_units\` (
    \`id\` varchar(36) NOT NULL,
    \`order_id\` varchar(36) NOT NULL,
    \`unit_number\` int NOT NULL,
    \`target_url\` varchar(500) NULL,
    \`generated_content\` text NULL,
    \`status\` varchar(50) NOT NULL DEFAULT 'PENDING',
    \`created_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    \`updated_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    INDEX \`IDX_order_units_order\` (\`order_id\`),
    PRIMARY KEY (\`id\`)
) ENGINE=InnoDB;

-- 3. Ensure tasks table has order_unit_id
ALTER TABLE \`tasks\` ADD COLUMN IF NOT EXISTS \`order_unit_id\` varchar(36) NULL;

-- 4. Seed the 4 Official YouTube Services
DELETE FROM \`service_pricing\` WHERE \`service_id\` IN ('yt-comment-001', 'yt-like-002', 'yt-sub-003', 'yt-combo-004');
DELETE FROM \`service_catalog\` WHERE \`id\` IN ('yt-comment-001', 'yt-like-002', 'yt-sub-003', 'yt-combo-004') OR \`code\` IN ('YOUTUBE_COMMENT', 'YOUTUBE_LIKE', 'YOUTUBE_SUBSCRIBE', 'YOUTUBE_COMBO');

-- 4.1 YouTube Comment (AI ON)
INSERT INTO \`service_catalog\` (
    \`id\`, \`code\`, \`name\`, \`description\`, \`category\`, \`service_type\`,
    \`is_active\`, \`version\`, \`review_mode\`, \`worker_limit\`, \`min_accept_hours\`, \`max_accept_hours\`,
    \`min_complete_hours\`, \`max_complete_hours\`, \`watchtime_seconds\`, \`ai_generator_enabled\`,
    \`ai_generator_config\`, \`link_field_label\`, \`link_field_placeholder\`, \`text_field_label\`, \`text_field_placeholder\`,
    \`admin_instructions\`, \`created_at\`, \`updated_at\`
) VALUES (
    'yt-comment-001', 'YOUTUBE_COMMENT', 'YouTube Video Comment',
    'Post a unique, high-quality comment on the target YouTube video.',
    'YouTube', 'comment',
    1, 1, 'buyer', 1, 24, 72, 48, 168, 0, 1,
    '{"enabled":true,"generator_type":"youtube_comment","language":"English","tone":"natural","uniqueness":true}',
    'Target Video URL', 'https://www.youtube.com/watch?v=...',
    'Comment Topic / Keywords', 'e.g. informative, great tutorial, honest review',
    '1. Open video link\n2. Copy assigned comment below\n3. Post comment on YouTube\n4. Upload screenshot proof',
    NOW(), NOW()
);

INSERT INTO \`service_pricing\` (
    \`id\`, \`service_id\`, \`buyer_unit_price\`, \`margin_type\`, \`margin_value\`, \`worker_reward\`,
    \`currency\`, \`version\`, \`is_active\`, \`created_at\`, \`updated_at\`
) VALUES (
    'yt-price-comment-001', 'yt-comment-001', 3.00, 'FIXED', 1.00, 2.00, 'INR', 1, 1, NOW(), NOW()
);

-- 4.2 YouTube Like (AI OFF)
INSERT INTO \`service_catalog\` (
    \`id\`, \`code\`, \`name\`, \`description\`, \`category\`, \`service_type\`,
    \`is_active\`, \`version\`, \`review_mode\`, \`worker_limit\`, \`min_accept_hours\`, \`max_accept_hours\`,
    \`min_complete_hours\`, \`max_complete_hours\`, \`watchtime_seconds\`, \`ai_generator_enabled\`,
    \`ai_generator_config\`, \`link_field_label\`, \`link_field_placeholder\`,
    \`admin_instructions\`, \`created_at\`, \`updated_at\`
) VALUES (
    'yt-like-002', 'YOUTUBE_LIKE', 'YouTube Video Like',
    'High retention real user likes on YouTube video.',
    'YouTube', 'like',
    1, 1, 'buyer', 1, 24, 72, 48, 168, 0, 0,
    '{"enabled":false,"generator_type":"none"}',
    'Target Video URL', 'https://www.youtube.com/watch?v=...',
    '1. Open video link\n2. Click Like button\n3. Upload screenshot proof',
    NOW(), NOW()
);

INSERT INTO \`service_pricing\` (
    \`id\`, \`service_id\`, \`buyer_unit_price\`, \`margin_type\`, \`margin_value\`, \`worker_reward\`,
    \`currency\`, \`version\`, \`is_active\`, \`created_at\`, \`updated_at\`
) VALUES (
    'yt-price-like-002', 'yt-like-002', 2.00, 'FIXED', 0.50, 1.50, 'INR', 1, 1, NOW(), NOW()
);

-- 4.3 YouTube Subscribe (AI OFF)
INSERT INTO \`service_catalog\` (
    \`id\`, \`code\`, \`name\`, \`description\`, \`category\`, \`service_type\`,
    \`is_active\`, \`version\`, \`review_mode\`, \`worker_limit\`, \`min_accept_hours\`, \`max_accept_hours\`,
    \`min_complete_hours\`, \`max_complete_hours\`, \`watchtime_seconds\`, \`ai_generator_enabled\`,
    \`ai_generator_config\`, \`link_field_label\`, \`link_field_placeholder\`,
    \`admin_instructions\`, \`created_at\`, \`updated_at\`
) VALUES (
    'yt-sub-003', 'YOUTUBE_SUBSCRIBE', 'YouTube Channel Subscribe',
    'Permanent subscribers from verified active accounts.',
    'YouTube', 'subscribe',
    1, 1, 'buyer', 1, 24, 72, 48, 168, 0, 0,
    '{"enabled":false,"generator_type":"none"}',
    'Target Channel URL', 'https://www.youtube.com/@channel',
    '1. Open channel link\n2. Click Subscribe button\n3. Upload screenshot proof',
    NOW(), NOW()
);

INSERT INTO \`service_pricing\` (
    \`id\`, \`service_id\`, \`buyer_unit_price\`, \`margin_type\`, \`margin_value\`, \`worker_reward\`,
    \`currency\`, \`version\`, \`is_active\`, \`created_at\`, \`updated_at\`
) VALUES (
    'yt-price-sub-003', 'yt-sub-003', 5.00, 'FIXED', 1.50, 3.50, 'INR', 1, 1, NOW(), NOW()
);

-- 4.4 YouTube Combo (Like + Subscribe + Comment, AI ON)
INSERT INTO \`service_catalog\` (
    \`id\`, \`code\`, \`name\`, \`description\`, \`category\`, \`service_type\`,
    \`is_active\`, \`version\`, \`review_mode\`, \`worker_limit\`, \`min_accept_hours\`, \`max_accept_hours\`,
    \`min_complete_hours\`, \`max_complete_hours\`, \`watchtime_seconds\`, \`ai_generator_enabled\`,
    \`ai_generator_config\`, \`link_field_label\`, \`link_field_placeholder\`, \`text_field_label\`, \`text_field_placeholder\`,
    \`admin_instructions\`, \`created_at\`, \`updated_at\`
) VALUES (
    'yt-combo-004', 'YOUTUBE_COMBO', 'YouTube Combo (Like + Sub + Comment)',
    'Complete engagement package: Like video + Subscribe to Channel + Post unique AI Comment.',
    'YouTube', 'combo',
    1, 1, 'buyer', 1, 24, 72, 48, 168, 60, 1,
    '{"enabled":true,"generator_type":"youtube_comment","language":"English","tone":"natural","uniqueness":true,"actions":{"like":true,"subscribe":true,"comment":true}}',
    'Target Video / Channel URL', 'https://www.youtube.com/watch?v=...',
    'Comment Topic / Keywords', 'e.g. fantastic content, subscribed!',
    '1. Open video link\n2. Watch for 60s and Like video\n3. Subscribe to the channel\n4. Copy assigned comment and post\n5. Upload screenshot proof',
    NOW(), NOW()
);

INSERT INTO \`service_pricing\` (
    \`id\`, \`service_id\`, \`buyer_unit_price\`, \`margin_type\`, \`margin_value\`, \`worker_reward\`,
    \`currency\`, \`version\`, \`is_active\`, \`created_at\`, \`updated_at\`
) VALUES (
    'yt-price-combo-004', 'yt-combo-004', 8.00, 'FIXED', 2.50, 5.50, 'INR', 1, 1, NOW(), NOW()
);
`;

    await ssh.execCommand(`cat << 'EOF' > /opt/task-engine/setup_youtube_ai.sql\n${sql}\nEOF`);
    const sqlRes = await ssh.execCommand('mysql < /opt/task-engine/setup_youtube_ai.sql');
    console.log('Database Setup Result:', sqlRes.stdout || 'Applied successfully!');
    if (sqlRes.stderr) console.error('Stderr:', sqlRes.stderr);

    // Verify services in database
    const checkRes = await ssh.execCommand(`mysql -e "SELECT id, code, name, category, ai_generator_enabled FROM task_platform.service_catalog;"`);
    console.log('\nSeeded Services in DB:\n', checkRes.stdout);

  } catch (err) {
    console.error('Error:', err);
  } finally {
    ssh.dispose();
  }
}

setupDatabase();
