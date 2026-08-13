import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    CreateDateColumn,
    UpdateDateColumn,
    ManyToOne,
    JoinColumn,
} from 'typeorm';

@Entity('tasks')
export class Task {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column({ name: 'order_id' })
    orderId: string;

    @Column({ name: 'campaign_id' })
    campaignId: string;

    @Column({ name: 'task_type' })
    taskType: string;

    @Column({ type: 'varchar', length: 50 })
    status: string;

    @Column({ type: 'json', nullable: true })
    requirements: any;

    @Column({ type: 'json', nullable: true })
    metadata: any;

    @Column({ name: 'assigned_to', nullable: true })
    assignedTo: string;

    @Column({ name: 'assigned_at', type: 'timestamp', nullable: true })
    assignedAt: Date;

    @Column({ name: 'accepted_at', type: 'timestamp', nullable: true })
    acceptedAt: Date;

    @Column({ name: 'started_at', type: 'timestamp', nullable: true })
    startedAt: Date;

    @Column({ name: 'submitted_at', type: 'timestamp', nullable: true })
    submittedAt: Date;

    @Column({ name: 'completed_at', type: 'timestamp', nullable: true })
    completedAt: Date;

    @Column({ name: 'deadline', type: 'timestamp', nullable: true })
    deadline: Date;

    @Column({ name: 'attempt_count', type: 'int', default: 0 })
    attemptCount: number;

    @Column({ name: 'reward_amount', type: 'decimal', precision: 10, scale: 2 })
    rewardAmount: number;

    @CreateDateColumn({ name: 'created_at' })
    createdAt: Date;

    @UpdateDateColumn({ name: 'updated_at' })
    updatedAt: Date;
}
