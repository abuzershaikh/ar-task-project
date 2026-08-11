import { MigrationInterface, QueryRunner } from 'typeorm';

export class InitialSchema1700000000000 implements MigrationInterface {
    name = 'InitialSchema1700000000000';

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`
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
        `);

        await queryRunner.query(`
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
        `);

        await queryRunner.query(`
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
        `);

        await queryRunner.query(`
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
                \`created_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
                \`updated_at\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
                PRIMARY KEY (\`id\`)
            ) ENGINE=InnoDB;
        `);

        await queryRunner.query(`
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
        `);

        await queryRunner.query(`
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
        `);

        await queryRunner.query(`
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
        `);

        await queryRunner.query(`
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
        `);

        await queryRunner.query(`
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
        `);

        await queryRunner.query(`
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
        `);

        await queryRunner.query(`
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
        `);

        await queryRunner.query(`
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
        `);

        await queryRunner.query(`
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
        `);

        await queryRunner.query(`
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
        `);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`DROP TABLE IF EXISTS \`audit_logs\``);
        await queryRunner.query(`DROP TABLE IF EXISTS \`notifications\``);
        await queryRunner.query(`DROP TABLE IF EXISTS \`files\``);
        await queryRunner.query(`DROP TABLE IF EXISTS \`ratings\``);
        await queryRunner.query(`DROP TABLE IF EXISTS \`payment_methods\``);
        await queryRunner.query(`DROP TABLE IF EXISTS \`kyc_profiles\``);
        await queryRunner.query(`DROP TABLE IF EXISTS \`withdrawals\``);
        await queryRunner.query(`DROP TABLE IF EXISTS \`earnings\``);
        await queryRunner.query(`DROP TABLE IF EXISTS \`task_submissions\``);
        await queryRunner.query(`DROP TABLE IF EXISTS \`tasks\``);
        await queryRunner.query(`DROP TABLE IF EXISTS \`orders\``);
        await queryRunner.query(`DROP TABLE IF EXISTS \`worker_scores\``);
        await queryRunner.query(`DROP TABLE IF EXISTS \`workers\``);
        await queryRunner.query(`DROP TABLE IF EXISTS \`users\``);
    }
}
