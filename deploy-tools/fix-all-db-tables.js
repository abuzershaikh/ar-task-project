const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function fixAllTables() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('Connected to VPS via SSH as root!');

    const schemaFixSql = `
USE \`task_platform\`;

-- 1. kyc_profiles table fix
DROP TABLE IF EXISTS \`kyc_profiles\`;
CREATE TABLE \`kyc_profiles\` (
    \`id\` varchar(36) NOT NULL,
    \`worker_id\` varchar(36) NOT NULL,
    \`status\` enum('DRAFT','SUBMITTED','UNDER_REVIEW','VERIFIED','REJECTED','EXPIRED') NOT NULL DEFAULT 'DRAFT',
    \`full_name\` varchar(255) NOT NULL,
    \`date_of_birth\` date NULL,
    \`gender\` varchar(50) NULL,
    \`address\` text NULL,
    \`city\` varchar(100) NULL,
    \`state\` varchar(100) NULL,
    \`pincode\` varchar(20) NULL,
    \`country\` varchar(100) NULL,
    \`bank_name\` varchar(255) NULL,
    \`account_number\` varchar(255) NULL,
    \`ifsc_code\` varchar(50) NULL,
    \`upi_id\` varchar(255) NULL,
    \`paypal_id\` varchar(255) NULL,
    \`submitted_at\` timestamp NULL,
    \`reviewed_by\` varchar(255) NULL,
    \`reviewed_at\` timestamp NULL,
    \`rejection_reason\` text NULL,
    \`expiry_date\` date NULL,
    \`metadata\` json NULL,
    \`created_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    \`updated_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    UNIQUE INDEX \`IDX_kyc_worker\` (\`worker_id\`),
    PRIMARY KEY (\`id\`)
) ENGINE=InnoDB;

-- 2. Ensure orders table has all columns
ALTER TABLE \`orders\` ADD COLUMN IF NOT EXISTS \`extension_count\` int NOT NULL DEFAULT 0;
ALTER TABLE \`orders\` ADD COLUMN IF NOT EXISTS \`total_slots\` int NOT NULL DEFAULT 0;
ALTER TABLE \`orders\` ADD COLUMN IF NOT EXISTS \`available_slots\` int NOT NULL DEFAULT 0;
ALTER TABLE \`orders\` ADD COLUMN IF NOT EXISTS \`completed_slots\` int NOT NULL DEFAULT 0;
ALTER TABLE \`orders\` ADD COLUMN IF NOT EXISTS \`failed_slots\` int NOT NULL DEFAULT 0;
ALTER TABLE \`orders\` ADD COLUMN IF NOT EXISTS \`unit_price\` decimal(10,2) NOT NULL DEFAULT 0.00;
ALTER TABLE \`orders\` ADD COLUMN IF NOT EXISTS \`total_budget\` decimal(10,2) NOT NULL DEFAULT 0.00;

-- 3. Ensure tasks table has all columns
ALTER TABLE \`tasks\` ADD COLUMN IF NOT EXISTS \`order_id\` varchar(36) NULL;
ALTER TABLE \`tasks\` ADD COLUMN IF NOT EXISTS \`worker_id\` varchar(36) NULL;
ALTER TABLE \`tasks\` ADD COLUMN IF NOT EXISTS \`reward_amount\` decimal(10,2) NOT NULL DEFAULT 0.00;
ALTER TABLE \`tasks\` ADD COLUMN IF NOT EXISTS \`worker_reward\` decimal(10,2) NOT NULL DEFAULT 0.00;

-- 4. Ensure workers table has all columns
ALTER TABLE \`workers\` ADD COLUMN IF NOT EXISTS \`full_name\` varchar(255) NULL;
ALTER TABLE \`workers\` ADD COLUMN IF NOT EXISTS \`phone\` varchar(50) NULL;
ALTER TABLE \`workers\` ADD COLUMN IF NOT EXISTS \`status\` varchar(50) NOT NULL DEFAULT 'active';
ALTER TABLE \`workers\` ADD COLUMN IF NOT EXISTS \`kyc_status\` varchar(50) NOT NULL DEFAULT 'pending';
ALTER TABLE \`workers\` ADD COLUMN IF NOT EXISTS \`total_earnings\` decimal(10,2) NOT NULL DEFAULT 0.00;
ALTER TABLE \`workers\` ADD COLUMN IF NOT EXISTS \`success_rate\` decimal(5,2) NOT NULL DEFAULT 0.00;
ALTER TABLE \`workers\` ADD COLUMN IF NOT EXISTS \`average_rating\` decimal(3,2) NOT NULL DEFAULT 0.00;

-- 5. Ensure buyers table has all columns
ALTER TABLE \`buyers\` ADD COLUMN IF NOT EXISTS \`company_name\` varchar(255) NULL;
ALTER TABLE \`buyers\` ADD COLUMN IF NOT EXISTS \`total_spent\` decimal(10,2) NOT NULL DEFAULT 0.00;
ALTER TABLE \`buyers\` ADD COLUMN IF NOT EXISTS \`wallet_balance\` decimal(10,2) NOT NULL DEFAULT 0.00;
ALTER TABLE \`buyers\` ADD COLUMN IF NOT EXISTS \`kyc_status\` varchar(50) NOT NULL DEFAULT 'pending';

-- 6. Ensure payments and transactions have all columns
ALTER TABLE \`payments\` ADD COLUMN IF NOT EXISTS \`amount\` decimal(10,2) NOT NULL DEFAULT 0.00;
ALTER TABLE \`payments\` ADD COLUMN IF NOT EXISTS \`currency\` varchar(10) NOT NULL DEFAULT 'INR';
ALTER TABLE \`payments\` ADD COLUMN IF NOT EXISTS \`status\` varchar(50) NOT NULL DEFAULT 'COMPLETED';
`;

    await ssh.execCommand(`cat << 'EOF' > /opt/task-engine/fix_all_schema.sql\n${schemaFixSql}\nEOF`);
    const sqlRes = await ssh.execCommand('mysql < /opt/task-engine/fix_all_schema.sql');
    console.log('SQL Execution output:', sqlRes.stdout || 'Applied successfully!');
    if (sqlRes.stderr) console.log('SQL stderr:', sqlRes.stderr);

    // Restart pm2 task-engine-api
    console.log('Restarting task-engine-api in pm2...');
    await ssh.execCommand('pm2 restart task-engine-api');
    console.log('PM2 restarted!');

  } catch (err) {
    console.error('Error:', err);
  } finally {
    ssh.dispose();
  }
}

fixAllTables();
