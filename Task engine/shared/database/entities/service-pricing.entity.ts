import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    CreateDateColumn,
    UpdateDateColumn,
    Index,
} from 'typeorm';
import { MarginType } from '../../modules/service-catalog/enums/margin-type.enum';

@Entity('service_pricing')
@Index(['serviceId', 'version'], { unique: true })
@Index(['serviceId', 'isActive'])
export class ServicePricing {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column({ name: 'service_id' })
    serviceId: string;

    @Column({ name: 'buyer_unit_price', type: 'decimal', precision: 10, scale: 2 })
    buyerUnitPrice: number;

    @Column({
        name: 'margin_type',
        type: 'enum',
        enum: MarginType,
        default: MarginType.FIXED,
    })
    marginType: MarginType;

    @Column({ name: 'margin_value', type: 'decimal', precision: 10, scale: 2 })
    marginValue: number;

    @Column({ name: 'worker_reward', type: 'decimal', precision: 10, scale: 2 })
    workerReward: number;

    @Column({ type: 'varchar', length: 10, default: 'INR' })
    currency: string;

    @Column({ type: 'int', default: 1 })
    version: number;

    @Column({ name: 'is_active', type: 'boolean', default: true })
    isActive: boolean;

    @CreateDateColumn({ name: 'effective_from' })
    effectiveFrom: Date;

    @Column({ name: 'effective_until', type: 'timestamp', nullable: true })
    effectiveUntil: Date;

    @CreateDateColumn({ name: 'created_at' })
    createdAt: Date;

    @UpdateDateColumn({ name: 'updated_at' })
    updatedAt: Date;
}
