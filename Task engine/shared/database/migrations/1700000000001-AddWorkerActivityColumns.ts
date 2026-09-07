import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddWorkerActivityColumns1700000000001 implements MigrationInterface {
    name = 'AddWorkerActivityColumns1700000000001';

    public async up(queryRunner: QueryRunner): Promise<void> {
        // Add last_active_at column — tracks worker's last meaningful activity
        await queryRunner.query(`
            ALTER TABLE \`workers\`
            ADD COLUMN \`last_active_at\` timestamp NULL DEFAULT NULL
        `);

        // Add performance_points column — tracks +1 completed / -3 rejected / -5 expired
        await queryRunner.query(`
            ALTER TABLE \`workers\`
            ADD COLUMN \`performance_points\` int NOT NULL DEFAULT 0
        `);

        // Add task_cooldown_until column — temporary cooldown for repeated rejections
        await queryRunner.query(`
            ALTER TABLE \`workers\`
            ADD COLUMN \`task_cooldown_until\` timestamp NULL DEFAULT NULL
        `);

        // Initialize last_active_at for existing active workers to NOW
        await queryRunner.query(`
            UPDATE \`workers\`
            SET \`last_active_at\` = NOW()
            WHERE \`status\` = 'active'
        `);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE \`workers\` DROP COLUMN \`task_cooldown_until\``);
        await queryRunner.query(`ALTER TABLE \`workers\` DROP COLUMN \`performance_points\``);
        await queryRunner.query(`ALTER TABLE \`workers\` DROP COLUMN \`last_active_at\``);
    }
}
