const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

const schemaSql = `
CREATE DATABASE IF NOT EXISTS \`task_platform\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE \`task_platform\`;

CREATE TABLE IF NOT EXISTS \`users\` (
    \`id\` varchar(36) NOT NULL,
    \`email\` varchar(255) NOT NULL,
    \`phone\` varchar(255) NULL,
    \`password\` varchar(255) NOT NULL,
    \`full_name\` varchar(255) NOT NULL,
    \`role\` enum('WORKER', 'BUYER', 'ADMIN', 'SUPER_ADMIN') NOT NULL,
    \`status\` enum('ACTIVE', 'INACTIVE', 'SUSPENDED', 'BANNED') NOT NULL DEFAULT 'ACTIVE',
    \`email_verified\` boolean NOT NULL DEFAULT false,
    \`phone_verified\` boolean NOT NULL DEFAULT false,
    \`refresh_token\` varchar(255) NULL,
    \`password_reset_token_hash\` varchar(255) NULL,
    \`password_reset_token_expires_at\` timestamp NULL,
    \`last_login\` timestamp NULL,
    \`login_attempts\` int NOT NULL DEFAULT 0,
    \`locked_until\` timestamp NULL,
    \`metadata\` json NULL,
    \`created_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    \`updated_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    UNIQUE INDEX \`IDX_users_email\` (\`email\`),
    UNIQUE INDEX \`IDX_users_phone\` (\`phone\`),
    PRIMARY KEY (\`id\`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS \`workers\` (
    \`id\` varchar(36) NOT NULL,
    \`user_id\` varchar(255) NOT NULL,
    \`status\` varchar(50) NOT NULL,
    \`kyc_status\` varchar(50) NOT NULL,
    \`profile\` json NULL,
    \`preferences\` json NULL,
    \`total_tasks_completed\` int NOT NULL DEFAULT 0,
    \`total_tasks_rejected\` int NOT NULL DEFAULT 0,
    \`success_rate\` decimal(5,2) NOT NULL DEFAULT 0.00,
    \`average_rating\` decimal(3,2) NOT NULL DEFAULT 0.00,
    \`total_earnings\` decimal(10,2) NOT NULL DEFAULT 0.00,
    \`created_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    \`updated_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (\`id\`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS \`worker_scores\` (
    \`id\` varchar(36) NOT NULL,
    \`worker_id\` varchar(255) NOT NULL,
    \`total_score\` decimal(5,2) NOT NULL,
    \`quality_score\` decimal(5,2) NOT NULL,
    \`completion_score\` decimal(5,2) NOT NULL,
    \`reliability_score\` decimal(5,2) NOT NULL,
    \`rating_score\` decimal(5,2) NOT NULL,
    \`recent_performance_score\` decimal(5,2) NOT NULL,
    \`experience_score\` decimal(5,2) NOT NULL,
    \`breakdown\` json NULL,
    \`created_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    \`updated_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (\`id\`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS \`orders\` (
    \`id\` varchar(36) NOT NULL,
    \`buyer_id\` varchar(255) NOT NULL,
    \`title\` varchar(100) NOT NULL,
    \`description\` text NULL,
    \`task_type\` varchar(255) NOT NULL,
    \`total_tasks_required\` int NOT NULL,
    \`tasks_completed\` int NOT NULL DEFAULT 0,
    \`reward_per_task\` decimal(10,2) NOT NULL,
    \`status\` varchar(50) NOT NULL,
    \`requirements\` json NULL,
    \`review_mode\` varchar(50) NOT NULL,
    \`buyer_unit_price\` decimal(10,2) NULL,
    \`worker_reward_snapshot\` decimal(10,2) NULL,
    \`platform_margin_snapshot\` decimal(10,2) NULL,
    \`service_code\` varchar(100) NULL,
    \`pricing_version\` int NOT NULL DEFAULT 1,
    \`total_amount\` decimal(10,2) NULL,
    \`time_to_accept_hours\` int NOT NULL DEFAULT 24,
    \`time_to_complete_hours\` int NOT NULL DEFAULT 48,
    \`campaign_expiry_date\` timestamp NULL,
    \`time_to_accept_hours_snapshot\` int NOT NULL DEFAULT 24,
    \`time_to_complete_hours_snapshot\` int NOT NULL DEFAULT 48,
    \`campaign_expiry_date_snapshot\` timestamp NULL,
    \`created_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    \`updated_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (\`id\`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS \`tasks\` (
    \`id\` varchar(36) NOT NULL,
    \`order_id\` varchar(255) NOT NULL,
    \`campaign_id\` varchar(255) NOT NULL,
    \`task_type\` varchar(255) NOT NULL,
    \`status\` varchar(50) NOT NULL,
    \`requirements\` json NULL,
    \`metadata\` json NULL,
    \`assigned_to\` varchar(255) NULL,
    \`assigned_at\` timestamp NULL,
    \`accepted_at\` timestamp NULL,
    \`started_at\` timestamp NULL,
    \`submitted_at\` timestamp NULL,
    \`completed_at\` timestamp NULL,
    \`deadline\` timestamp NULL,
    \`attempt_count\` int NOT NULL DEFAULT 0,
    \`reward_amount\` decimal(10,2) NOT NULL,
    \`created_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    \`updated_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (\`id\`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS \`task_submissions\` (
    \`id\` varchar(36) NOT NULL,
    \`task_id\` varchar(255) NOT NULL,
    \`worker_id\` varchar(255) NOT NULL,
    \`data\` json NOT NULL,
    \`proofs\` json NULL,
    \`status\` varchar(50) NOT NULL,
    \`review_status\` varchar(50) NULL,
    \`reviewed_by\` varchar(255) NULL,
    \`reviewed_at\` timestamp NULL,
    \`review_notes\` text NULL,
    \`created_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    \`updated_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (\`id\`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS \`earnings\` (
    \`id\` varchar(36) NOT NULL,
    \`worker_id\` varchar(255) NOT NULL,
    \`task_id\` varchar(255) NOT NULL,
    \`amount\` decimal(10,2) NOT NULL,
    \`type\` varchar(50) NOT NULL,
    \`status\` varchar(50) NOT NULL,
    \`metadata\` json NULL,
    \`ledger_entry_id\` varchar(255) NULL,
    \`created_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (\`id\`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS \`withdrawals\` (
    \`id\` varchar(36) NOT NULL,
    \`worker_id\` varchar(255) NOT NULL,
    \`amount\` decimal(10,2) NOT NULL,
    \`status\` enum('REQUESTED', 'UNDER_REVIEW', 'PROCESSING', 'PAID', 'REJECTED', 'FAILED') NOT NULL DEFAULT 'REQUESTED',
    \`payment_method_id\` varchar(255) NOT NULL,
    \`transaction_id\` varchar(255) NULL,
    \`provider_reference\` varchar(255) NULL,
    \`requested_at\` timestamp NOT NULL,
    \`processed_at\` timestamp NULL,
    \`paid_at\` timestamp NULL,
    \`rejection_reason\` text NULL,
    \`failure_reason\` text NULL,
    \`idempotency_key\` varchar(255) NULL,
    \`metadata\` json NULL,
    \`created_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    \`updated_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    UNIQUE INDEX \`IDX_withdrawals_idempotency_key\` (\`idempotency_key\`),
    INDEX \`IDX_withdrawals_worker_id\` (\`worker_id\`),
    INDEX \`IDX_withdrawals_status\` (\`status\`),
    PRIMARY KEY (\`id\`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS \`kyc_profiles\` (
    \`id\` varchar(36) NOT NULL,
    \`worker_id\` varchar(255) NOT NULL,
    \`status\` enum('DRAFT', 'SUBMITTED', 'UNDER_REVIEW', 'VERIFIED', 'REJECTED', 'EXPIRED') NOT NULL DEFAULT 'DRAFT',
    \`full_name\` varchar(255) NOT NULL,
    \`date_of_birth\` date NULL,
    \`gender\` varchar(255) NULL,
    \`address\` text NULL,
    \`city\` varchar(255) NULL,
    \`state\` varchar(255) NULL,
    \`pincode\` varchar(255) NULL,
    \`country\` varchar(255) NULL,
    \`document_type\` enum('AADHAAR', 'PAN', 'PASSPORT', 'DRIVING_LICENSE', 'VOTER_ID') NULL,
    \`document_number\` varchar(255) NULL,
    \`documents\` json NULL,
    \`submitted_at\` timestamp NULL,
    \`reviewed_by\` varchar(255) NULL,
    \`reviewed_at\` timestamp NULL,
    \`rejection_reason\` text NULL,
    \`expiry_date\` date NULL,
    \`metadata\` json NULL,
    \`created_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    \`updated_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    UNIQUE INDEX \`IDX_kyc_worker_id\` (\`worker_id\`),
    PRIMARY KEY (\`id\`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS \`payment_methods\` (
    \`id\` varchar(36) NOT NULL,
    \`worker_id\` varchar(255) NOT NULL,
    \`type\` enum('BANK', 'UPI') NOT NULL,
    \`is_default\` boolean NOT NULL DEFAULT false,
    \`is_verified\` boolean NOT NULL DEFAULT false,
    \`account_holder_name\` varchar(255) NULL,
    \`account_number\` varchar(255) NULL,
    \`masked_account_number\` varchar(255) NULL,
    \`ifsc_code\` varchar(255) NULL,
    \`bank_name\` varchar(255) NULL,
    \`upi_id\` varchar(255) NULL,
    \`masked_upi_id\` varchar(255) NULL,
    \`metadata\` json NULL,
    \`created_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    \`updated_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    INDEX \`IDX_payment_methods_worker_id\` (\`worker_id\`),
    PRIMARY KEY (\`id\`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS \`ratings\` (
    \`id\` varchar(36) NOT NULL,
    \`task_id\` varchar(255) NOT NULL,
    \`worker_id\` varchar(255) NOT NULL,
    \`buyer_id\` varchar(255) NOT NULL,
    \`rating\` int NOT NULL,
    \`feedback\` text NULL,
    \`categories\` json NULL,
    \`created_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    \`updated_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    UNIQUE INDEX \`IDX_ratings_task_id\` (\`task_id\`),
    INDEX \`IDX_ratings_worker_id\` (\`worker_id\`),
    INDEX \`IDX_ratings_buyer_id\` (\`buyer_id\`),
    PRIMARY KEY (\`id\`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS \`files\` (
    \`id\` varchar(36) NOT NULL,
    \`uploaded_by\` varchar(255) NOT NULL,
    \`type\` enum('IMAGE', 'VIDEO', 'DOCUMENT', 'PROOF', 'KYC_DOCUMENT') NOT NULL,
    \`original_name\` varchar(255) NOT NULL,
    \`file_name\` varchar(255) NOT NULL,
    \`file_path\` varchar(255) NOT NULL,
    \`mime_type\` varchar(255) NOT NULL,
    \`file_size\` bigint NOT NULL,
    \`entity_type\` varchar(255) NULL,
    \`entity_id\` varchar(255) NULL,
    \`metadata\` json NULL,
    \`created_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    INDEX \`IDX_files_uploaded_by\` (\`uploaded_by\`),
    INDEX \`IDX_files_entity\` (\`entity_type\`, \`entity_id\`),
    PRIMARY KEY (\`id\`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS \`notifications\` (
    \`id\` varchar(36) NOT NULL,
    \`user_id\` varchar(255) NOT NULL,
    \`type\` varchar(50) NOT NULL,
    \`title\` varchar(255) NOT NULL,
    \`message\` text NOT NULL,
    \`is_read\` boolean NOT NULL DEFAULT false,
    \`read_at\` timestamp NULL,
    \`entity_type\` varchar(255) NULL,
    \`entity_id\` varchar(255) NULL,
    \`data\` json NULL,
    \`created_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    INDEX \`IDX_notifications_user_id\` (\`user_id\`),
    INDEX \`IDX_notifications_is_read\` (\`is_read\`),
    PRIMARY KEY (\`id\`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS \`audit_logs\` (
    \`id\` varchar(36) NOT NULL,
    \`actor_id\` varchar(255) NOT NULL,
    \`actor_role\` varchar(255) NOT NULL,
    \`action\` varchar(255) NOT NULL,
    \`entity_type\` varchar(255) NOT NULL,
    \`entity_id\` varchar(255) NOT NULL,
    \`previous_state\` json NULL,
    \`new_state\` json NULL,
    \`metadata\` json NULL,
    \`ip\` varchar(255) NULL,
    \`user_agent\` text NULL,
    \`request_id\` varchar(255) NULL,
    \`created_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    INDEX \`IDX_audit_actor_id\` (\`actor_id\`),
    INDEX \`IDX_audit_entity\` (\`entity_type\`, \`entity_id\`),
    INDEX \`IDX_audit_action\` (\`action\`),
    INDEX \`IDX_audit_created_at\` (\`created_at\`),
    PRIMARY KEY (\`id\`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS \`service_catalog\` (
    \`id\` varchar(36) NOT NULL,
    \`code\` varchar(100) NOT NULL,
    \`name\` varchar(150) NOT NULL,
    \`description\` text NULL,
    \`elements\` json NULL,
    \`review_mode\` varchar(50) NOT NULL DEFAULT 'buyer',
    \`is_active\` boolean NOT NULL DEFAULT true,
    \`version\` int NOT NULL DEFAULT 1,
    \`created_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    \`updated_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    UNIQUE INDEX \`IDX_service_catalog_code\` (\`code\`),
    PRIMARY KEY (\`id\`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS \`service_pricing\` (
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

CREATE TABLE IF NOT EXISTS \`task_assignments\` (
    \`id\` varchar(36) NOT NULL,
    \`task_id\` varchar(255) NOT NULL,
    \`campaign_id\` varchar(255) NOT NULL,
    \`worker_id\` varchar(255) NOT NULL,
    \`attempt_number\` int NOT NULL DEFAULT 1,
    \`status\` enum('ASSIGNED', 'ACCEPTED', 'STARTED', 'SUBMITTED', 'EXPIRED', 'EARLY_RELEASED', 'COMPLETED', 'REJECTED') NOT NULL DEFAULT 'ASSIGNED',
    \`release_reason\` varchar(100) NULL,
    \`assigned_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    \`accepted_at\` timestamp NULL,
    \`started_at\` timestamp NULL,
    \`submitted_at\` timestamp NULL,
    \`expired_at\` timestamp NULL,
    \`completed_at\` timestamp NULL,
    \`accept_deadline\` timestamp NULL,
    \`completion_deadline\` timestamp NULL,
    \`created_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    \`updated_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    UNIQUE INDEX \`IDX_task_assignments_task_attempt\` (\`task_id\`, \`attempt_number\`),
    INDEX \`IDX_task_assignments_campaign_worker\` (\`campaign_id\`, \`worker_id\`),
    INDEX \`IDX_task_assignments_worker\` (\`worker_id\`),
    PRIMARY KEY (\`id\`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS \`campaign_worker_participation\` (
    \`id\` varchar(36) NOT NULL,
    \`campaign_id\` varchar(255) NOT NULL,
    \`worker_id\` varchar(255) NOT NULL,
    \`status\` enum('ASSIGNED', 'COMPLETED', 'EXPIRED', 'REJECTED') NOT NULL DEFAULT 'ASSIGNED',
    \`assigned_count\` int NOT NULL DEFAULT 1,
    \`completed_count\` int NOT NULL DEFAULT 0,
    \`expired_count\` int NOT NULL DEFAULT 0,
    \`rejected_count\` int NOT NULL DEFAULT 0,
    \`first_assigned_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    \`last_assigned_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    \`created_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    \`updated_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    UNIQUE INDEX \`IDX_cwp_campaign_worker\` (\`campaign_id\`, \`worker_id\`),
    INDEX \`IDX_cwp_campaign\` (\`campaign_id\`),
    INDEX \`IDX_cwp_worker\` (\`worker_id\`),
    PRIMARY KEY (\`id\`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS \`payment_transactions\` (
    \`id\` varchar(36) NOT NULL,
    \`provider\` varchar(50) NOT NULL,
    \`provider_payment_id\` varchar(150) NOT NULL,
    \`provider_event_id\` varchar(150) NULL,
    \`order_id\` varchar(255) NOT NULL,
    \`buyer_id\` varchar(255) NOT NULL,
    \`status\` enum('INITIATED', 'CAPTURED', 'FAILED', 'REFUNDED') NOT NULL DEFAULT 'INITIATED',
    \`amount\` decimal(10,2) NOT NULL,
    \`currency\` varchar(10) NOT NULL DEFAULT 'INR',
    \`raw_payload\` json NULL,
    \`verified_at\` timestamp NULL,
    \`created_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    \`updated_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    UNIQUE INDEX \`IDX_pt_provider_payment\` (\`provider\`, \`provider_payment_id\`),
    INDEX \`IDX_pt_order\` (\`order_id\`),
    INDEX \`IDX_pt_buyer\` (\`buyer_id\`),
    PRIMARY KEY (\`id\`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS \`task_generation_jobs\` (
    \`id\` varchar(36) NOT NULL,
    \`order_id\` varchar(255) NOT NULL,
    \`status\` enum('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED') NOT NULL DEFAULT 'PENDING',
    \`total_tasks_required\` int NOT NULL,
    \`generated_tasks_count\` int NOT NULL DEFAULT 0,
    \`worker_reward_snapshot\` decimal(10,2) NOT NULL,
    \`last_error\` text NULL,
    \`created_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    \`updated_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    UNIQUE INDEX \`IDX_tgj_order\` (\`order_id\`),
    PRIMARY KEY (\`id\`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS \`system_settings\` (
    \`id\` varchar(36) NOT NULL,
    \`key\` varchar(100) NOT NULL,
    \`value\` json NOT NULL,
    \`description\` text NULL,
    \`is_sensitive\` boolean NOT NULL DEFAULT false,
    \`updated_by\` varchar(255) NULL,
    \`created_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    \`updated_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    UNIQUE INDEX \`IDX_system_settings_key\` (\`key\`),
    PRIMARY KEY (\`id\`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS \`wallets\` (
    \`id\` varchar(36) NOT NULL,
    \`user_id\` varchar(255) NOT NULL,
    \`available_balance\` decimal(12,2) NOT NULL DEFAULT 0.00,
    \`reserved_balance\` decimal(12,2) NOT NULL DEFAULT 0.00,
    \`created_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    \`updated_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    UNIQUE INDEX \`IDX_wallets_user_id\` (\`user_id\`),
    PRIMARY KEY (\`id\`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS \`wallet_transactions\` (
    \`id\` varchar(36) NOT NULL,
    \`wallet_id\` varchar(36) NOT NULL,
    \`type\` enum('CREDIT', 'DEBIT', 'HOLD', 'RELEASE') NOT NULL,
    \`amount\` decimal(12,2) NOT NULL,
    \`balance_after\` decimal(12,2) NOT NULL,
    \`description\` varchar(255) NOT NULL,
    \`reference_id\` varchar(255) NULL,
    \`reference_type\` varchar(50) NULL,
    \`created_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    INDEX \`IDX_wallet_tx_wallet\` (\`wallet_id\`),
    PRIMARY KEY (\`id\`)
) ENGINE=InnoDB;
`;

async function setupSchema() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
      readyTimeout: 30000,
    });
    console.log('Connected to VPS!');

    console.log('Writing schema.sql to VPS...');
    await ssh.execCommand(`cat << 'EOF' > /opt/task-engine/schema.sql\n${schemaSql}\nEOF`);

    console.log('Executing schema.sql in MariaDB...');
    await ssh.execCommand('mysql < /opt/task-engine/schema.sql');

    const tables = await ssh.execCommand('mysql -e "USE task_platform; SHOW TABLES;"');
    console.log('\n✅ Created Tables in task_platform:\n', tables.stdout);

    console.log('Seeding SuperAdmin Users on VPS...');
    const seedScript = `
const bcrypt = require('bcrypt');
const mysql = require('mysql2/promise');
const crypto = require('crypto');

async function main() {
  const conn = await mysql.createConnection({
    host: 'localhost',
    user: 'taskapp',
    password: 'taskapp_password',
    database: 'task_platform'
  });

  const admins = [
    { email: 'admin@taskpost.com', pass: 'Admin@123456', name: 'Super Admin' },
    { email: 'snapbizux@gmail.com', pass: '80978097', name: 'Snapbiz Admin' }
  ];

  for (const a of admins) {
    const hash = await bcrypt.hash(a.pass, 10);
    const [rows] = await conn.execute('SELECT id FROM users WHERE email = ?', [a.email]);
    if (rows.length > 0) {
      await conn.execute('UPDATE users SET password = ?, role = "SUPER_ADMIN", status = "ACTIVE" WHERE email = ?', [hash, a.email]);
      console.log('✅ Updated admin:', a.email);
    } else {
      const id = crypto.randomUUID();
      await conn.execute('INSERT INTO users (id, email, full_name, password, role, status, email_verified, phone_verified, created_at, updated_at) VALUES (?, ?, ?, ?, "SUPER_ADMIN", "ACTIVE", 1, 1, NOW(), NOW())', [id, a.email, a.name, hash]);
      console.log('✅ Created admin:', a.email);
    }
  }

  // Seed default service catalog & pricing
  const services = [
    {
      code: 'YOUTUBE_LIKE',
      name: 'YouTube Video Like',
      desc: 'High quality real user likes on YouTube videos',
      buyerUnitPrice: 2.00,
      marginType: 'FIXED',
      marginValue: 0.50,
      workerReward: 1.50
    },
    {
      code: 'YOUTUBE_SUBSCRIBE',
      name: 'YouTube Channel Subscribe',
      desc: 'Permanent subscribers from verified accounts',
      buyerUnitPrice: 5.00,
      marginType: 'FIXED',
      marginValue: 1.50,
      workerReward: 3.50
    },
    {
      code: 'APP_INSTALL',
      name: 'Android App Install & Open',
      desc: 'Install app from Play Store and keep open for 1 minute',
      buyerUnitPrice: 10.00,
      marginType: 'PERCENTAGE',
      marginValue: 30.00,
      workerReward: 7.00
    }
  ];

  for (const s of services) {
    const [rows] = await conn.execute('SELECT id FROM service_catalog WHERE code = ?', [s.code]);
    let serviceId;
    if (rows.length > 0) {
      serviceId = rows[0].id;
    } else {
      serviceId = crypto.randomUUID();
      await conn.execute('INSERT INTO service_catalog (id, code, name, description, is_active, version, review_mode, created_at, updated_at) VALUES (?, ?, ?, ?, 1, 1, "buyer", NOW(), NOW())', [serviceId, s.code, s.name, s.desc]);
      await conn.execute('INSERT INTO service_pricing (id, service_id, buyer_unit_price, margin_type, margin_value, worker_reward, currency, version, is_active, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, "INR", 1, 1, NOW(), NOW())', [crypto.randomUUID(), serviceId, s.buyerUnitPrice, s.marginType, s.marginValue, s.workerReward]);
      console.log('✅ Seeded service:', s.name);
    }
  }

  await conn.end();
}
main().catch(err => { console.error('Seed error:', err); process.exit(1); });
`;
    await ssh.execCommand(`node -e "${seedScript.replace(/"/g, '\\"').replace(/\n/g, ' ')}"`, { cwd: '/opt/task-engine' });

    console.log('✅ Seed executed successfully!');

    // Restart PM2 to reload everything fresh
    console.log('Restarting task-engine-api...');
    await ssh.execCommand('pm2 restart task-engine-api');
    await new Promise(r => setTimeout(r, 2000));

    // Test login API
    console.log('\n--- Testing SuperAdmin Login Endpoint ---');
    const loginRes = await ssh.execCommand(`curl -s -X POST http://localhost:3000/api/v1/auth/login -H "Content-Type: application/json" -d '{"email":"snapbizux@gmail.com","password":"80978097"}'`);
    console.log('Snapbiz Admin Login Response:\n', loginRes.stdout);

    const loginRes2 = await ssh.execCommand(`curl -s -X POST http://localhost:3000/api/v1/auth/login -H "Content-Type: application/json" -d '{"email":"admin@taskpost.com","password":"Admin@123456"}'`);
    console.log('\nTaskPost Admin Login Response:\n', loginRes2.stdout);

    // Test Swagger
    const swaggerRes = await ssh.execCommand('curl -s -I http://localhost:3000/api/docs/');
    console.log('\nSwagger HTTP Status:\n', swaggerRes.stdout);

    // Final PM2 verification
    const pm2Final = await ssh.execCommand('pm2 list');
    console.log('\nFinal PM2 Process List:\n', pm2Final.stdout);

  } catch (err) {
    console.error('Setup failed:', err);
  } finally {
    ssh.dispose();
  }
}

setupSchema();
