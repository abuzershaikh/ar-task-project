import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateWorkerCompletedIdentities1700000000003 implements MigrationInterface {
    name = 'CreateWorkerCompletedIdentities1700000000003';

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`
            CREATE TABLE IF NOT EXISTS \`worker_completed_identities\` (
                \`id\` INT AUTO_INCREMENT PRIMARY KEY,
                \`worker_key\` VARCHAR(191) NOT NULL,
                \`entity_key\` VARCHAR(191) NOT NULL,
                \`task_id\` VARCHAR(64) NULL,
                \`created_at\` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE KEY \`uk_worker_entity\` (\`worker_key\`, \`entity_key\`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        `);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`
            DROP TABLE IF EXISTS \`worker_completed_identities\`;
        `);
    }
}
