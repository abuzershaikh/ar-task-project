import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    CreateDateColumn,
    UpdateDateColumn,
    Index,
} from 'typeorm';

export enum PaymentTransactionStatus {
    INITIATED = 'INITIATED',
    CAPTURED = 'CAPTURED',
    FAILED = 'FAILED',
    REFUNDED = 'REFUNDED',
}

@Entity('payment_transactions')
@Index(['provider', 'providerPaymentId'], { unique: true })
@Index(['orderId'])
@Index(['buyerId'])
export class PaymentTransaction {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column({ type: 'varchar', length: 50 })
    provider: string; // RAZORPAY, STRIPE, CASHFREE

    @Column({ name: 'provider_payment_id', type: 'varchar', length: 150 })
    providerPaymentId: string;

    @Column({ name: 'provider_event_id', type: 'varchar', length: 150, nullable: true })
    providerEventId: string;

    @Column({ name: 'order_id' })
    orderId: string;

    @Column({ name: 'buyer_id' })
    buyerId: string;

    @Column({
        type: 'enum',
        enum: PaymentTransactionStatus,
        default: PaymentTransactionStatus.INITIATED,
    })
    status: PaymentTransactionStatus;

    @Column({ type: 'decimal', precision: 10, scale: 2 })
    amount: number;

    @Column({ type: 'varchar', length: 10, default: 'INR' })
    currency: string;

    @Column({ type: 'json', nullable: true })
    rawPayload: any;

    @Column({ name: 'verified_at', type: 'timestamp', nullable: true })
    verifiedAt: Date;

    @CreateDateColumn({ name: 'created_at' })
    createdAt: Date;

    @UpdateDateColumn({ name: 'updated_at' })
    updatedAt: Date;
}
