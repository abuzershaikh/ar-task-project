import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddWorkerActivityColumns1700000000001 implements MigrationInterface {
    name = 'AddWorkerActivityColumns1700000000001';

    public async up(queryRunner: QueryRunner): Promise<void> {
        const hasLastActive = await queryRunner.hasColumn('workers', 'last_active_at');
        if (!hasLastActive) {
            await queryRunner.query(`
                ALTER TABLE \`workers\`
                ADD COLUMN \`last_active_at\` timestamp NULL DEFAULT NULL
            `);
        }

        const hasPoints = await queryRunner.hasColumn('workers', 'performance_points');
        if (!hasPoints) {
            await queryRunner.query(`
                ALTER TABLE \`workers\`
                ADD COLUMN \`performance_points\` int NOT NULL DEFAULT 0
            `);
        }

        const hasCooldown = await queryRunner.hasColumn('workers', 'task_cooldown_until');
        if (!hasCooldown) {
            await queryRunner.query(`
                ALTER TABLE \`workers\`
                ADD COLUMN \`task_cooldown_until\` timestamp NULL DEFAULT NULL
            `);
        }

        try {
            await queryRunner.query(`
                UPDATE \`workers\`
                SET \`last_active_at\` = NOW()
                WHERE \`status\` = 'active' AND \`last_active_at\` IS NULL
            `);
        } catch (_) {}
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        try {
            if (await queryRunner.hasColumn('workers', 'task_cooldown_until')) {
                await queryRunner.query(`ALTER TABLE \`workers\` DROP COLUMN \`task_cooldown_until\``);
            }
            if (await queryRunner.hasColumn('workers', 'performance_points')) {
                await queryRunner.query(`ALTER TABLE \`workers\` DROP COLUMN \`performance_points\``);
            }
            if (await queryRunner.hasColumn('workers', 'last_active_at')) {
                await queryRunner.query(`ALTER TABLE \`workers\` DROP COLUMN \`last_active_at\``);
            }
        } catch (_) {}
    }
}
