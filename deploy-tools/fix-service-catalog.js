const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function fixTables() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    const fixSql = `
USE \`task_platform\`;

DROP TABLE IF EXISTS \`service_pricing\`;
DROP TABLE IF EXISTS \`service_catalog\`;

CREATE TABLE \`service_catalog\` (
    \`id\` varchar(36) NOT NULL,
    \`code\` varchar(100) NOT NULL,
    \`name\` varchar(150) NOT NULL,
    \`description\` text NULL,
    \`is_active\` boolean NOT NULL DEFAULT true,
    \`elements\` json NULL,
    \`review_mode\` varchar(50) NOT NULL DEFAULT 'buyer',
    \`worker_limit\` int NOT NULL DEFAULT 1,
    \`min_accept_hours\` int NOT NULL DEFAULT 1,
    \`max_accept_hours\` int NOT NULL DEFAULT 72,
    \`min_complete_hours\` int NOT NULL DEFAULT 1,
    \`max_complete_hours\` int NOT NULL DEFAULT 168,
    \`watchtime_seconds\` int NOT NULL DEFAULT 0,
    \`video_tutorial_url\` varchar(500) NULL,
    \`audio_guide_url\` varchar(500) NULL,
    \`admin_instructions\` text NULL,
    \`link_field_label\` varchar(150) NULL DEFAULT 'Target Link / URL',
    \`link_field_placeholder\` varchar(250) NULL DEFAULT 'https://...',
    \`text_field_label\` varchar(150) NULL DEFAULT 'Custom Text / Instructions',
    \`text_field_placeholder\` varchar(250) NULL DEFAULT 'Enter text, comments or keywords...',
    \`watch_time_options\` json NULL,
    \`version\` int NOT NULL DEFAULT 1,
    \`created_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    \`updated_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    \`deleted_at\` timestamp NULL DEFAULT NULL,
    UNIQUE INDEX \`IDX_service_catalog_code\` (\`code\`),
    PRIMARY KEY (\`id\`)
) ENGINE=InnoDB;

CREATE TABLE \`service_pricing\` (
    \`id\` varchar(36) NOT NULL,
    \`service_id\` varchar(255) NOT NULL,
    \`buyer_unit_price\` decimal(10,2) NOT NULL,
    \`margin_type\` enum('FIXED', 'PERCENTAGE') NOT NULL DEFAULT 'FIXED',
    \`margin_value\` decimal(10,2) NOT NULL,
    \`worker_reward\` decimal(10,2) NOT NULL,
    \`currency\` varchar(10) NOT NULL DEFAULT 'INR',
    \`version\` int NOT NULL DEFAULT 1,
    \`is_active\` boolean NOT NULL DEFAULT true,
    \`effective_from\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    \`effective_until\` timestamp NULL,
    \`created_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    \`updated_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    UNIQUE INDEX \`IDX_service_pricing_service_version\` (\`service_id\`, \`version\`),
    INDEX \`IDX_service_pricing_active\` (\`service_id\`, \`is_active\`),
    PRIMARY KEY (\`id\`)
) ENGINE=InnoDB;

INSERT INTO service_catalog (id, code, name, description, is_active, version, review_mode, created_at, updated_at)
VALUES 
('c8f1e5a2-1111-4a11-b111-000000000001', 'YOUTUBE_LIKE', 'YouTube Video Like', 'High quality real user likes on YouTube videos', 1, 1, 'buyer', NOW(), NOW()),
('c8f1e5a2-2222-4a11-b111-000000000002', 'YOUTUBE_SUBSCRIBE', 'YouTube Channel Subscribe', 'Permanent subscribers from verified accounts', 1, 1, 'buyer', NOW(), NOW()),
('c8f1e5a2-3333-4a11-b111-000000000003', 'APP_INSTALL', 'Android App Install & Open', 'Install app from Play Store and keep open for 1 minute', 1, 1, 'buyer', NOW(), NOW());

INSERT INTO service_pricing (id, service_id, buyer_unit_price, margin_type, margin_value, worker_reward, currency, version, is_active, created_at, updated_at)
VALUES 
('p8f1e5a2-1111-4a11-b111-000000000001', 'c8f1e5a2-1111-4a11-b111-000000000001', 2.00, 'FIXED', 0.50, 1.50, 'INR', 1, 1, NOW(), NOW()),
('p8f1e5a2-2222-4a11-b111-000000000002', 'c8f1e5a2-2222-4a11-b111-000000000002', 5.00, 'FIXED', 1.50, 3.50, 'INR', 1, 1, NOW(), NOW()),
('p8f1e5a2-3333-4a11-b111-000000000003', 'c8f1e5a2-3333-4a11-b111-000000000003', 10.00, 'PERCENTAGE', 30.00, 7.00, 'INR', 1, 1, NOW(), NOW());
`;

    await ssh.execCommand(`cat << 'EOF' > /opt/task-engine/fix.sql\n${fixSql}\nEOF`);
    await ssh.execCommand('mysql < /opt/task-engine/fix.sql');
    console.log('✅ Service Catalog tables recreated with all columns!');

    // Test API again
    const loginRes = await ssh.execCommand(`curl -s -X POST http://localhost:3000/api/v1/auth/login -H "Content-Type: application/json" -d '{"email":"snapbizux@gmail.com","password":"80978097"}'`);
    const data = JSON.parse(loginRes.stdout);
    const token = data.data.accessToken;

    const servicesRes = await ssh.execCommand(`curl -s http://localhost:3000/api/v1/admin/services -H "Authorization: Bearer ${token}"`);
    console.log('\nAdmin Services API Output:\n', servicesRes.stdout);

    const buyerServicesRes = await ssh.execCommand(`curl -s http://localhost:3000/api/v1/buyer/services -H "Authorization: Bearer ${token}"`);
    console.log('\nBuyer Services API Output:\n', buyerServicesRes.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}
fixTables();
