import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('wallets')
export class Wallet {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column({ type: 'uuid', unique: true })
    userId: string; // References User entity

    @Column({ type: 'decimal', precision: 12, scale: 2, default: 0 })
    availableBalance: number;

    @Column({ type: 'decimal', precision: 12, scale: 2, default: 0 })
    reservedBalance: number;

    @CreateDateColumn()
    createdAt: Date;

    @UpdateDateColumn()
    updatedAt: Date;
}
