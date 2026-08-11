import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    CreateDateColumn,
    UpdateDateColumn,
    Index,
} from 'typeorm';

export enum TaskGenerationJobStatus {
    PENDING = 'PENDING',
    PROCESSING = 'PROCESSING',
    COMPLETED = 'COMPLETED',
    FAILED = 'FAILED',
}

@Entity('task_generation_jobs')
@Index(['orderId'], { unique: true })
export class TaskGenerationJob {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column({ name: 'order_id', unique: true })
    orderId: string;

    @Column({
        type: 'enum',
        enum: TaskGenerationJobStatus,
        default: TaskGenerationJobStatus.PENDING,
    })
    status: TaskGenerationJobStatus;

    @Column({ name: 'total_tasks_required', type: 'int' })
    totalTasksRequired: number;

    @Column({ name: 'generated_tasks_count', type: 'int', default: 0 })
    generatedTasksCount: number;

    @Column({ name: 'worker_reward_snapshot', type: 'decimal', precision: 10, scale: 2 })
    workerRewardSnapshot: number;

    @Column({ name: 'last_error', type: 'text', nullable: true })
    lastError: string;

    @CreateDateColumn({ name: 'created_at' })
    createdAt: Date;

    @UpdateDateColumn({ name: 'updated_at' })
    updatedAt: Date;
}
