import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity('wallet_transactions')
export class WalletTransaction {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column({ name: 'wallet_id', type: 'varchar', length: 36 })
    walletId: string;

    @Column({ type: 'varchar', length: 50 })
    type: string;

    @Column({ type: 'decimal', precision: 12, scale: 2 })
    amount: number;

    @Column({ name: 'balance_after', type: 'decimal', precision: 12, scale: 2, default: 0 })
    balanceAfter: number;

    @Column({ name: 'reference_id', type: 'varchar', length: 255, nullable: true })
    referenceId: string;

    @Column({ name: 'reference_type', type: 'varchar', length: 50, nullable: true })
    referenceType: string;

    @Column({ type: 'varchar', length: 255, default: 'Transaction' })
    description: string;

    @Column({ type: 'varchar', length: 50, default: 'COMPLETED' })
    status: string;

    @CreateDateColumn({ name: 'created_at' })
    createdAt: Date;
}
