import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    CreateDateColumn,
    UpdateDateColumn,
    Index,
} from 'typeorm';

export enum TaskAssignmentStatus {
    ASSIGNED = 'ASSIGNED',
    ACCEPTED = 'ACCEPTED',
    STARTED = 'STARTED',
    SUBMITTED = 'SUBMITTED',
    EXPIRED = 'EXPIRED',
    EARLY_RELEASED = 'EARLY_RELEASED',
    COMPLETED = 'COMPLETED',
    REJECTED = 'REJECTED',
}

@Entity('task_assignments')
@Index(['taskId', 'attemptNumber'], { unique: true })
@Index(['campaignId', 'workerId'])
@Index(['workerId'])
export class TaskAssignment {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column({ name: 'task_id' })
    taskId: string;

    @Column({ name: 'campaign_id' })
    campaignId: string;

    @Column({ name: 'worker_id' })
    workerId: string;

    @Column({ name: 'attempt_number', type: 'int', default: 1 })
    attemptNumber: number;

    @Column({
        type: 'enum',
        enum: TaskAssignmentStatus,
        default: TaskAssignmentStatus.ASSIGNED,
    })
    status: TaskAssignmentStatus;

    @Column({ name: 'release_reason', type: 'varchar', length: 100, nullable: true })
    releaseReason: string;

    @CreateDateColumn({ name: 'assigned_at' })
    assignedAt: Date;

    @Column({ name: 'accepted_at', type: 'timestamp', nullable: true })
    acceptedAt: Date;

    @Column({ name: 'started_at', type: 'timestamp', nullable: true })
    startedAt: Date;

    @Column({ name: 'submitted_at', type: 'timestamp', nullable: true })
    submittedAt: Date;

    @Column({ name: 'expired_at', type: 'timestamp', nullable: true })
    expiredAt: Date;

    @Column({ name: 'completed_at', type: 'timestamp', nullable: true })
    completedAt: Date;

    @Column({ name: 'accept_deadline', type: 'timestamp', nullable: true })
    acceptDeadline: Date;

    @Column({ name: 'completion_deadline', type: 'timestamp', nullable: true })
    completionDeadline: Date;

    @CreateDateColumn({ name: 'created_at' })
    createdAt: Date;

    @UpdateDateColumn({ name: 'updated_at' })
    updatedAt: Date;
}
