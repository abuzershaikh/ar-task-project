import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    CreateDateColumn,
    UpdateDateColumn,
    Index,
} from 'typeorm';

export enum UserRole {
    WORKER = 'WORKER',
    BUYER = 'BUYER',
    ADMIN = 'ADMIN',
    SUPER_ADMIN = 'SUPER_ADMIN',
}

export enum UserStatus {
    ACTIVE = 'ACTIVE',
    INACTIVE = 'INACTIVE',
    SUSPENDED = 'SUSPENDED',
    BANNED = 'BANNED',
}

@Entity('users')
@Index(['email'], { unique: true })
@Index(['phone'], { unique: true })
export class User {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column({ unique: true })
    email: string;

    @Column({ nullable: true, unique: true })
    phone: string;

    @Column({ select: false })
    password: string;

    @Column({ name: 'full_name' })
    fullName: string;

    @Column({ type: 'enum', enum: UserRole })
    role: UserRole;

    @Column({ type: 'enum', enum: UserStatus, default: UserStatus.ACTIVE })
    status: UserStatus;

    @Column({ name: 'email_verified', default: false })
    emailVerified: boolean;

    @Column({ name: 'phone_verified', default: false })
    phoneVerified: boolean;

    @Column({ name: 'refresh_token', nullable: true, select: false })
    refreshToken: string;

    @Column({ name: 'password_reset_token_hash', nullable: true, select: false })
    passwordResetTokenHash: string;

    @Column({ name: 'password_reset_token_expires_at', type: 'timestamp', nullable: true })
    passwordResetTokenExpiresAt: Date;

    @Column({ name: 'last_login', type: 'timestamp', nullable: true })
    lastLogin: Date;

    @Column({ name: 'login_attempts', default: 0 })
    loginAttempts: number;

    @Column({ name: 'locked_until', type: 'timestamp', nullable: true })
    lockedUntil: Date;

    @Column({ type: 'json', nullable: true })
    metadata: any;

    @CreateDateColumn({ name: 'created_at' })
    createdAt: Date;

    @UpdateDateColumn({ name: 'updated_at' })
    updatedAt: Date;
}
