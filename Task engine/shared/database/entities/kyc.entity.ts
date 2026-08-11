import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    CreateDateColumn,
    UpdateDateColumn,
    Index,
} from 'typeorm';

export enum KycStatus {
    DRAFT = 'DRAFT',
    SUBMITTED = 'SUBMITTED',
    UNDER_REVIEW = 'UNDER_REVIEW',
    VERIFIED = 'VERIFIED',
    REJECTED = 'REJECTED',
    EXPIRED = 'EXPIRED',
}

export enum DocumentType {
    AADHAAR = 'AADHAAR',
    PAN = 'PAN',
    PASSPORT = 'PASSPORT',
    DRIVING_LICENSE = 'DRIVING_LICENSE',
    VOTER_ID = 'VOTER_ID',
}

@Entity('kyc_profiles')
@Index(['workerId'], { unique: true })
export class KycProfile {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column({ name: 'worker_id' })
    workerId: string;

    @Column({ type: 'enum', enum: KycStatus, default: KycStatus.DRAFT })
    status: KycStatus;

    @Column({ name: 'full_name' })
    fullName: string;

    @Column({ name: 'date_of_birth', type: 'date', nullable: true })
    dateOfBirth: Date;

    @Column({ nullable: true })
    gender: string;

    @Column({ type: 'text', nullable: true })
    address: string;

    @Column({ nullable: true })
    city: string;

    @Column({ nullable: true })
    state: string;

    @Column({ nullable: true })
    pincode: string;

    @Column({ nullable: true })
    country: string;

    @Column({ name: 'document_type', type: 'enum', enum: DocumentType, nullable: true })
    documentType: DocumentType;

    @Column({ name: 'document_number', nullable: true })
    documentNumber: string;

    @Column({ type: 'json', nullable: true })
    documents: any;

    @Column({ name: 'submitted_at', type: 'timestamp', nullable: true })
    submittedAt: Date;

    @Column({ name: 'reviewed_by', nullable: true })
    reviewedBy: string;

    @Column({ name: 'reviewed_at', type: 'timestamp', nullable: true })
    reviewedAt: Date;

    @Column({ name: 'rejection_reason', type: 'text', nullable: true })
    rejectionReason: string;

    @Column({ name: 'expiry_date', type: 'date', nullable: true })
    expiryDate: Date;

    @Column({ type: 'json', nullable: true })
    metadata: any;

    @CreateDateColumn({ name: 'created_at' })
    createdAt: Date;

    @UpdateDateColumn({ name: 'updated_at' })
    updatedAt: Date;
}
