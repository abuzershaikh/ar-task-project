import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    CreateDateColumn,
    UpdateDateColumn,
} from 'typeorm';

@Entity('workers')
export class Worker {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column({ name: 'user_id' })
    userId: string;

    @Column({ type: 'varchar', length: 50 })
    status: string;

    @Column({ name: 'kyc_status', type: 'varchar', length: 50 })
    kycStatus: string;

    @Column({ type: 'json', nullable: true })
    profile: any;

    @Column({ type: 'json', nullable: true })
    preferences: any;

    @Column({ name: 'total_tasks_completed', type: 'int', default: 0 })
    totalTasksCompleted: number;

    @Column({ name: 'total_tasks_rejected', type: 'int', default: 0 })
    totalTasksRejected: number;

    @Column({ name: 'success_rate', type: 'decimal', precision: 5, scale: 2, default: 0 })
    successRate: number;

    @Column({ name: 'average_rating', type: 'decimal', precision: 3, scale: 2, default: 0 })
    averageRating: number;

    @Column({ name: 'total_earnings', type: 'decimal', precision: 10, scale: 2, default: 0 })
    totalEarnings: number;

    @CreateDateColumn({ name: 'created_at' })
    createdAt: Date;

    @UpdateDateColumn({ name: 'updated_at' })
    updatedAt: Date;
}
