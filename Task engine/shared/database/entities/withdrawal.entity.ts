import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    CreateDateColumn,
    UpdateDateColumn,
    Index,
} from 'typeorm';

export enum WithdrawalStatus {
    REQUESTED = 'REQUESTED',
    UNDER_REVIEW = 'UNDER_REVIEW',
    PROCESSING = 'PROCESSING',
    PAID = 'PAID',
    REJECTED = 'REJECTED',
    FAILED = 'FAILED',
}

@Entity('withdrawals')
@Index(['workerId'])
@Index(['status'])
export class Withdrawal {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column({ name: 'worker_id' })
    workerId: string;

    @Column({ type: 'decimal', precision: 10, scale: 2 })
    amount: number;

    @Column({ type: 'enum', enum: WithdrawalStatus, default: WithdrawalStatus.REQUESTED })
    status: WithdrawalStatus;

    @Column({ name: 'payment_method_id' })
    paymentMethodId: string;

    @Column({ name: 'transaction_id', nullable: true })
    transactionId: string;

    @Column({ name: 'provider_reference', nullable: true })
    providerReference: string;

    @Column({ name: 'requested_at', type: 'timestamp' })
    requestedAt: Date;

    @Column({ name: 'processed_at', type: 'timestamp', nullable: true })
    processedAt: Date;

    @Column({ name: 'paid_at', type: 'timestamp', nullable: true })
    paidAt: Date;

    @Column({ name: 'rejection_reason', type: 'text', nullable: true })
    rejectionReason: string;

    @Column({ name: 'failure_reason', type: 'text', nullable: true })
    failureReason: string;

    @Column({ name: 'idempotency_key', nullable: true, unique: true })
    idempotencyKey: string;

    @Column({ type: 'json', nullable: true })
    metadata: any;

    @CreateDateColumn({ name: 'created_at' })
    createdAt: Date;

    @UpdateDateColumn({ name: 'updated_at' })
    updatedAt: Date;
}
