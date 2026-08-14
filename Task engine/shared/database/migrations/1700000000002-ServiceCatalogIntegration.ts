import { MigrationInterface, QueryRunner } from 'typeorm';

export class ServiceCatalogIntegration1700000000002 implements MigrationInterface {
    name = 'ServiceCatalogIntegration1700000000002';

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`
            ALTER TABLE \`service_catalog\`
                ADD COLUMN IF NOT EXISTS \`elements\` json NULL,
                ADD COLUMN IF NOT EXISTS \`review_mode\` varchar(50) NOT NULL DEFAULT 'buyer';
        `);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`
            ALTER TABLE \`service_catalog\`
                DROP COLUMN IF EXISTS \`elements\`,
                DROP COLUMN IF EXISTS \`review_mode\`;
        `);
    }
}
