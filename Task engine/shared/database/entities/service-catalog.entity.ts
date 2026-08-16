import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    CreateDateColumn,
    UpdateDateColumn,
    Index,
} from 'typeorm';

@Entity('service_catalog')
export class ServiceCatalog {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column({ type: 'varchar', length: 100, unique: true })
    code: string;

    @Column({ type: 'varchar', length: 150 })
    name: string;

    @Column({ type: 'text', nullable: true })
    description: string;

    @Column({ name: 'is_active', type: 'boolean', default: true })
    isActive: boolean;

    @Column({ type: 'json', nullable: true })
    elements: any; // Defines the form inputs (ITemplateElement array)

    @Column({ name: 'review_mode', type: 'varchar', length: 50, default: 'buyer' })
    reviewMode: string; // 'buyer' | 'admin' | 'automatic'

    @Column({ name: 'min_accept_hours', type: 'int', default: 1 })
    minAcceptHours: number;

    @Column({ name: 'max_accept_hours', type: 'int', default: 72 })
    maxAcceptHours: number;

    @Column({ name: 'min_complete_hours', type: 'int', default: 1 })
    minCompleteHours: number;

    @Column({ name: 'max_complete_hours', type: 'int', default: 168 })
    maxCompleteHours: number;

    @Column({ name: 'watchtime_seconds', type: 'int', default: 0 })
    watchtimeSeconds: number;

    @Column({ type: 'int', default: 1 })
    version: number;

    @CreateDateColumn({ name: 'created_at' })
    createdAt: Date;

    @UpdateDateColumn({ name: 'updated_at' })
    updatedAt: Date;
}
