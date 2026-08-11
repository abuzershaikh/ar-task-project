import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddMissingTables1700000000001 implements MigrationInterface {
    name = 'AddMissingTables1700000000001';

    public async up(queryRunner: QueryRunner): Promise<void> {
        // 1. Service Catalog
        await queryRunner.query(`
            CREATE TABLE IF NOT EXISTS \`service_catalog\` (
                \`id\` varchar(36) NOT NULL,
                \`code\` varchar(100) NOT NULL,
                \`name\` varchar(150) NOT NULL,
                \`description\` text NULL,
                \`is_active\` boolean NOT NULL DEFAULT true,
                \`version\` int NOT NULL DEFAULT 1,
                \`created_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
                \`updated_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
                UNIQUE INDEX \`IDX_service_catalog_code\` (\`code\`),
                PRIMARY KEY (\`id\`)
            ) ENGINE=InnoDB;
        `);

        // 2. Service Pricing
        await queryRunner.query(`
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
        `);

        // 3. Task Assignments
        await queryRunner.query(`
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
        `);

        // 4. Campaign Worker Participation
        await queryRunner.query(`
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
        `);

        // 5. Payment Transactions
        await queryRunner.query(`
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
        `);

        // 6. Task Generation Jobs
        await queryRunner.query(`
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
        `);

        // 7. System Settings
        await queryRunner.query(`
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
        `);

        // Update orders table with new pricing columns from entity
        await queryRunner.query(`
            ALTER TABLE \`orders\`
                ADD COLUMN IF NOT EXISTS \`buyer_unit_price\` decimal(10,2) NULL,
                ADD COLUMN IF NOT EXISTS \`worker_reward_snapshot\` decimal(10,2) NULL,
                ADD COLUMN IF NOT EXISTS \`platform_margin_snapshot\` decimal(10,2) NULL,
                ADD COLUMN IF NOT EXISTS \`service_code\` varchar(100) NULL,
                ADD COLUMN IF NOT EXISTS \`pricing_version\` int NOT NULL DEFAULT 1,
                ADD COLUMN IF NOT EXISTS \`total_amount\` decimal(10,2) NULL,
                ADD COLUMN IF NOT EXISTS \`time_to_accept_hours\` int NOT NULL DEFAULT 24,
                ADD COLUMN IF NOT EXISTS \`time_to_complete_hours\` int NOT NULL DEFAULT 48,
                ADD COLUMN IF NOT EXISTS \`campaign_expiry_date\` timestamp NULL,
                ADD COLUMN IF NOT EXISTS \`time_to_accept_hours_snapshot\` int NOT NULL DEFAULT 24,
                ADD COLUMN IF NOT EXISTS \`time_to_complete_hours_snapshot\` int NOT NULL DEFAULT 48,
                ADD COLUMN IF NOT EXISTS \`campaign_expiry_date_snapshot\` timestamp NULL;
        `);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`DROP TABLE IF EXISTS \`system_settings\``);
        await queryRunner.query(`DROP TABLE IF EXISTS \`task_generation_jobs\``);
        await queryRunner.query(`DROP TABLE IF EXISTS \`payment_transactions\``);
        await queryRunner.query(`DROP TABLE IF EXISTS \`campaign_worker_participation\``);
        await queryRunner.query(`DROP TABLE IF EXISTS \`task_assignments\``);
        await queryRunner.query(`DROP TABLE IF EXISTS \`service_pricing\``);
        await queryRunner.query(`DROP TABLE IF EXISTS \`service_catalog\``);
    }
}
