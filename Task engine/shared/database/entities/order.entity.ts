import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    CreateDateColumn,
    UpdateDateColumn,
} from 'typeorm';

@Entity('orders')
export class Order {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column({ name: 'buyer_id' })
    buyerId: string;

    @Column({ type: 'varchar', length: 100 })
    title: string;

    @Column({ type: 'text', nullable: true })
    description: string;

    @Column({ name: 'task_type' })
    taskType: string;

    @Column({ name: 'total_tasks_required', type: 'int' })
    totalTasksRequired: number;

    @Column({ name: 'tasks_completed', type: 'int', default: 0 })
    tasksCompleted: number;

    @Column({ name: 'reward_per_task', type: 'decimal', precision: 10, scale: 2 })
    rewardPerTask: number;

    @Column({ name: 'buyer_unit_price', type: 'decimal', precision: 10, scale: 2, nullable: true })
    buyerUnitPrice: number;

    @Column({ name: 'worker_reward_snapshot', type: 'decimal', precision: 10, scale: 2, nullable: true })
    workerRewardSnapshot: number;

    @Column({ name: 'platform_margin_snapshot', type: 'decimal', precision: 10, scale: 2, nullable: true })
    platformMarginSnapshot: number;

    @Column({ name: 'service_code', type: 'varchar', length: 100, nullable: true })
    serviceCode: string;

    @Column({ name: 'pricing_version', type: 'int', default: 1 })
    pricingVersion: number;

    @Column({ name: 'total_amount', type: 'decimal', precision: 10, scale: 2, nullable: true })
    totalAmount: number;

    @Column({ type: 'varchar', length: 50 })
    status: string;

    @Column({ type: 'json', nullable: true })
    requirements: any;

    @Column({ name: 'review_mode', type: 'varchar', length: 50 })
    reviewMode: string;

    @Column({ name: 'time_to_accept_hours', type: 'int', default: 24 })
    timeToAcceptHours: number;

    @Column({ name: 'time_to_complete_hours', type: 'int', default: 48 })
    timeToCompleteHours: number;

    @Column({ name: 'campaign_expiry_date', type: 'timestamp', nullable: true })
    campaignExpiryDate: Date;

    @Column({ name: 'time_to_accept_hours_snapshot', type: 'int', default: 24 })
    timeToAcceptHoursSnapshot: number;

    @Column({ name: 'time_to_complete_hours_snapshot', type: 'int', default: 48 })
    timeToCompleteHoursSnapshot: number;

    @Column({ name: 'campaign_expiry_date_snapshot', type: 'timestamp', nullable: true })
    campaignExpiryDateSnapshot: Date;

    @CreateDateColumn({ name: 'created_at' })
    createdAt: Date;

    @UpdateDateColumn({ name: 'updated_at' })
    updatedAt: Date;
}
