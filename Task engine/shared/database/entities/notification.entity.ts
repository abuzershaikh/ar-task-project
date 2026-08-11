import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    CreateDateColumn,
    Index,
} from 'typeorm';

export enum NotificationType {
    TASK_ASSIGNED = 'TASK_ASSIGNED',
    TASK_ACCEPTED = 'TASK_ACCEPTED',
    TASK_DEADLINE_APPROACHING = 'TASK_DEADLINE_APPROACHING',
    TASK_APPROVED = 'TASK_APPROVED',
    TASK_REJECTED = 'TASK_REJECTED',
    EARNING_POSTED = 'EARNING_POSTED',
    WITHDRAWAL_REQUESTED = 'WITHDRAWAL_REQUESTED',
    WITHDRAWAL_PROCESSING = 'WITHDRAWAL_PROCESSING',
    WITHDRAWAL_PAID = 'WITHDRAWAL_PAID',
    KYC_APPROVED = 'KYC_APPROVED',
    KYC_REJECTED = 'KYC_REJECTED',
    ORDER_PROGRESS = 'ORDER_PROGRESS',
    REVIEW_REQUIRED = 'REVIEW_REQUIRED',
}

@Entity('notifications')
@Index(['userId'])
@Index(['isRead'])
export class Notification {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column({ name: 'user_id' })
    userId: string;

    @Column({ type: 'enum', enum: NotificationType })
    type: NotificationType;

    @Column()
    title: string;

    @Column({ type: 'text' })
    message: string;

    @Column({ name: 'is_read', default: false })
    isRead: boolean;

    @Column({ name: 'read_at', type: 'timestamp', nullable: true })
    readAt: Date;

    @Column({ name: 'entity_type', nullable: true })
    entityType: string;

    @Column({ name: 'entity_id', nullable: true })
    entityId: string;

    @Column({ type: 'json', nullable: true })
    data: any;

    @CreateDateColumn({ name: 'created_at' })
    createdAt: Date;
}
