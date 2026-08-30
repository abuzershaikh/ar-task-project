const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function fixFullSchema() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('Connected to VPS!');

    const sql = `
USE \`task_platform\`;

-- Orders columns
ALTER TABLE \`orders\` ADD COLUMN IF NOT EXISTS \`buyer_id\` varchar(36) NULL;
ALTER TABLE \`orders\` ADD COLUMN IF NOT EXISTS \`title\` varchar(100) NULL;
ALTER TABLE \`orders\` ADD COLUMN IF NOT EXISTS \`description\` text NULL;
ALTER TABLE \`orders\` ADD COLUMN IF NOT EXISTS \`task_type\` varchar(100) NULL;
ALTER TABLE \`orders\` ADD COLUMN IF NOT EXISTS \`total_tasks_required\` int NOT NULL DEFAULT 1;
ALTER TABLE \`orders\` ADD COLUMN IF NOT EXISTS \`tasks_completed\` int NOT NULL DEFAULT 0;
ALTER TABLE \`orders\` ADD COLUMN IF NOT EXISTS \`reward_per_task\` decimal(10,2) NOT NULL DEFAULT 0.00;
ALTER TABLE \`orders\` ADD COLUMN IF NOT EXISTS \`buyer_unit_price\` decimal(10,2) NULL;
ALTER TABLE \`orders\` ADD COLUMN IF NOT EXISTS \`worker_reward_snapshot\` decimal(10,2) NULL;
ALTER TABLE \`orders\` ADD COLUMN IF NOT EXISTS \`platform_margin_snapshot\` decimal(10,2) NULL;
ALTER TABLE \`orders\` ADD COLUMN IF NOT EXISTS \`service_code\` varchar(100) NULL;
ALTER TABLE \`orders\` ADD COLUMN IF NOT EXISTS \`pricing_version\` int NOT NULL DEFAULT 1;
ALTER TABLE \`orders\` ADD COLUMN IF NOT EXISTS \`total_amount\` decimal(10,2) NULL;
ALTER TABLE \`orders\` ADD COLUMN IF NOT EXISTS \`status\` varchar(50) NOT NULL DEFAULT 'ACTIVE';
ALTER TABLE \`orders\` ADD COLUMN IF NOT EXISTS \`requirements\` json NULL;
ALTER TABLE \`orders\` ADD COLUMN IF NOT EXISTS \`review_mode\` varchar(50) NOT NULL DEFAULT 'buyer';
ALTER TABLE \`orders\` ADD COLUMN IF NOT EXISTS \`time_to_accept_hours\` int NOT NULL DEFAULT 24;
ALTER TABLE \`orders\` ADD COLUMN IF NOT EXISTS \`time_to_complete_hours\` int NOT NULL DEFAULT 48;
ALTER TABLE \`orders\` ADD COLUMN IF NOT EXISTS \`campaign_expiry_date\` timestamp NULL;
ALTER TABLE \`orders\` ADD COLUMN IF NOT EXISTS \`time_to_accept_hours_snapshot\` int NOT NULL DEFAULT 24;
ALTER TABLE \`orders\` ADD COLUMN IF NOT EXISTS \`time_to_complete_hours_snapshot\` int NOT NULL DEFAULT 48;
ALTER TABLE \`orders\` ADD COLUMN IF NOT EXISTS \`campaign_expiry_date_snapshot\` timestamp NULL;
ALTER TABLE \`orders\` ADD COLUMN IF NOT EXISTS \`extension_count\` int NOT NULL DEFAULT 0;
ALTER TABLE \`orders\` ADD COLUMN IF NOT EXISTS \`extension_history\` json NULL;

-- Tasks columns
ALTER TABLE \`tasks\` ADD COLUMN IF NOT EXISTS \`order_id\` varchar(36) NULL;
ALTER TABLE \`tasks\` ADD COLUMN IF NOT EXISTS \`campaign_id\` varchar(36) NULL;
ALTER TABLE \`tasks\` ADD COLUMN IF NOT EXISTS \`task_type\` varchar(100) NULL;
ALTER TABLE \`tasks\` ADD COLUMN IF NOT EXISTS \`status\` varchar(50) NOT NULL DEFAULT 'AVAILABLE';
ALTER TABLE \`tasks\` ADD COLUMN IF NOT EXISTS \`requirements\` json NULL;
ALTER TABLE \`tasks\` ADD COLUMN IF NOT EXISTS \`metadata\` json NULL;
ALTER TABLE \`tasks\` ADD COLUMN IF NOT EXISTS \`assigned_to\` varchar(36) NULL;
ALTER TABLE \`tasks\` ADD COLUMN IF NOT EXISTS \`assigned_at\` timestamp NULL;
ALTER TABLE \`tasks\` ADD COLUMN IF NOT EXISTS \`accepted_at\` timestamp NULL;
ALTER TABLE \`tasks\` ADD COLUMN IF NOT EXISTS \`started_at\` timestamp NULL;
ALTER TABLE \`tasks\` ADD COLUMN IF NOT EXISTS \`submitted_at\` timestamp NULL;
ALTER TABLE \`tasks\` ADD COLUMN IF NOT EXISTS \`completed_at\` timestamp NULL;
ALTER TABLE \`tasks\` ADD COLUMN IF NOT EXISTS \`deadline\` timestamp NULL;
ALTER TABLE \`tasks\` ADD COLUMN IF NOT EXISTS \`attempt_count\` int NOT NULL DEFAULT 0;
ALTER TABLE \`tasks\` ADD COLUMN IF NOT EXISTS \`reward_amount\` decimal(10,2) NOT NULL DEFAULT 0.00;

-- Workers columns
ALTER TABLE \`workers\` ADD COLUMN IF NOT EXISTS \`user_id\` varchar(36) NOT NULL;
ALTER TABLE \`workers\` ADD COLUMN IF NOT EXISTS \`status\` varchar(50) NOT NULL DEFAULT 'ACTIVE';
ALTER TABLE \`workers\` ADD COLUMN IF NOT EXISTS \`kyc_status\` varchar(50) NOT NULL DEFAULT 'VERIFIED';
ALTER TABLE \`workers\` ADD COLUMN IF NOT EXISTS \`profile\` json NULL;
ALTER TABLE \`workers\` ADD COLUMN IF NOT EXISTS \`preferences\` json NULL;
ALTER TABLE \`workers\` ADD COLUMN IF NOT EXISTS \`total_tasks_completed\` int NOT NULL DEFAULT 0;
ALTER TABLE \`workers\` ADD COLUMN IF NOT EXISTS \`total_tasks_rejected\` int NOT NULL DEFAULT 0;
ALTER TABLE \`workers\` ADD COLUMN IF NOT EXISTS \`success_rate\` decimal(5,2) NOT NULL DEFAULT 100.00;
ALTER TABLE \`workers\` ADD COLUMN IF NOT EXISTS \`average_rating\` decimal(3,2) NOT NULL DEFAULT 5.00;
ALTER TABLE \`workers\` ADD COLUMN IF NOT EXISTS \`total_earnings\` decimal(10,2) NOT NULL DEFAULT 0.00;
`;

    await ssh.execCommand(`cat << 'EOF' > /opt/task-engine/fix_full_schema.sql\n${sql}\nEOF`);
    const sqlRes = await ssh.execCommand('mysql < /opt/task-engine/fix_full_schema.sql');
    console.log('SQL Result:', sqlRes.stdout || 'Done');
    if (sqlRes.stderr) console.error('SQL Stderr:', sqlRes.stderr);

    console.log('Restarting PM2...');
    await ssh.execCommand('pm2 restart task-engine-api');
    console.log('PM2 restarted successfully!');

  } catch (err) {
    console.error('Error:', err);
  } finally {
    ssh.dispose();
  }
}

fixFullSchema();
