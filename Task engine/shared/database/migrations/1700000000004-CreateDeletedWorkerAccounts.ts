import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateDeletedWorkerAccounts1700000000004 implements MigrationInterface {
    name = 'CreateDeletedWorkerAccounts1700000000004';

    async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`CREATE TABLE IF NOT EXISTS deleted_worker_accounts (
            identity_hash CHAR(64) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY,
            deleted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB`);
    }

    async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query('DROP TABLE deleted_worker_accounts');
    }
}
