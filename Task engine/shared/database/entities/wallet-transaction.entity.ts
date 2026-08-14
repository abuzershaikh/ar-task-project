import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity('wallet_transactions')
export class WalletTransaction {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column({ type: 'uuid' })
    walletId: string;

    @Column({ type: 'varchar', length: 50 })
    type: 'CREDIT' | 'DEBIT' | 'RESERVE' | 'RELEASE';

    @Column({ type: 'decimal', precision: 12, scale: 2 })
    amount: number;

    @Column({ type: 'varchar', length: 100, nullable: true })
    referenceId: string; // Order ID, Payment Gateway ID, etc.

    @Column({ type: 'varchar', length: 255, nullable: true })
    description: string;

    @Column({ type: 'varchar', length: 50, default: 'COMPLETED' })
    status: 'PENDING' | 'COMPLETED' | 'FAILED';

    @CreateDateColumn()
    createdAt: Date;
}
