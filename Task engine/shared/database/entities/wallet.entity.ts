import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('wallets')
export class Wallet {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column({ name: 'user_id', type: 'uuid', unique: true })
    userId: string; // References User entity

    @Column({ name: 'available_balance', type: 'decimal', precision: 12, scale: 2, default: 0 })
    availableBalance: number;

    @Column({ name: 'reserved_balance', type: 'decimal', precision: 12, scale: 2, default: 0 })
    reservedBalance: number;

    @CreateDateColumn({ name: 'created_at' })
    createdAt: Date;

    @UpdateDateColumn({ name: 'updated_at' })
    updatedAt: Date;
}
