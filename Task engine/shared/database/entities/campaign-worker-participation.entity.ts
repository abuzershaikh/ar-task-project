import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    CreateDateColumn,
    UpdateDateColumn,
    Index,
} from 'typeorm';

export enum ParticipationStatus {
    ASSIGNED = 'ASSIGNED',
    COMPLETED = 'COMPLETED',
    EXPIRED = 'EXPIRED',
    REJECTED = 'REJECTED',
}

@Entity('campaign_worker_participation')
@Index(['campaignId', 'workerId'], { unique: true })
@Index(['campaignId'])
@Index(['workerId'])
export class CampaignWorkerParticipation {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column({ name: 'campaign_id' })
    campaignId: string;

    @Column({ name: 'worker_id' })
    workerId: string;

    @Column({
        type: 'enum',
        enum: ParticipationStatus,
        default: ParticipationStatus.ASSIGNED,
    })
    status: ParticipationStatus;

    @Column({ name: 'assigned_count', type: 'int', default: 1 })
    assignedCount: number;

    @Column({ name: 'completed_count', type: 'int', default: 0 })
    completedCount: number;

    @Column({ name: 'expired_count', type: 'int', default: 0 })
    expiredCount: number;

    @Column({ name: 'rejected_count', type: 'int', default: 0 })
    rejectedCount: number;

    @CreateDateColumn({ name: 'first_assigned_at' })
    firstAssignedAt: Date;

    @UpdateDateColumn({ name: 'last_assigned_at' })
    lastAssignedAt: Date;

    @CreateDateColumn({ name: 'created_at' })
    createdAt: Date;

    @UpdateDateColumn({ name: 'updated_at' })
    updatedAt: Date;
}
