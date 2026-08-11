import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    CreateDateColumn,
    UpdateDateColumn,
    Index,
} from 'typeorm';

export enum PaymentMethodType {
    BANK = 'BANK',
    UPI = 'UPI',
}

@Entity('payment_methods')
@Index(['workerId'])
export class PaymentMethod {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column({ name: 'worker_id' })
    workerId: string;

    @Column({ type: 'enum', enum: PaymentMethodType })
    type: PaymentMethodType;

    @Column({ name: 'is_default', default: false })
    isDefault: boolean;

    @Column({ name: 'is_verified', default: false })
    isVerified: boolean;

    // Bank details
    @Column({ name: 'account_holder_name', nullable: true })
    accountHolderName: string;

    @Column({ name: 'account_number', nullable: true, select: false })
    accountNumber: string;

    @Column({ name: 'masked_account_number', nullable: true })
    maskedAccountNumber: string;

    @Column({ name: 'ifsc_code', nullable: true })
    ifscCode: string;

    @Column({ name: 'bank_name', nullable: true })
    bankName: string;

    // UPI details
    @Column({ name: 'upi_id', nullable: true, select: false })
    upiId: string;

    @Column({ name: 'masked_upi_id', nullable: true })
    maskedUpiId: string;

    @Column({ type: 'json', nullable: true })
    metadata: any;

    @CreateDateColumn({ name: 'created_at' })
    createdAt: Date;

    @UpdateDateColumn({ name: 'updated_at' })
    updatedAt: Date;
}
