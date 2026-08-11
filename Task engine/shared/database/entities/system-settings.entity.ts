import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    CreateDateColumn,
    UpdateDateColumn,
} from 'typeorm';

@Entity('system_settings')
export class SystemSetting {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column({ type: 'varchar', length: 100, unique: true })
    key: string;

    @Column({ type: 'json' })
    value: any;

    @Column({ type: 'text', nullable: true })
    description: string;

    @Column({ name: 'is_sensitive', type: 'boolean', default: false })
    isSensitive: boolean;

    @Column({ name: 'updated_by', nullable: true })
    updatedBy: string;

    @CreateDateColumn({ name: 'created_at' })
    createdAt: Date;

    @UpdateDateColumn({ name: 'updated_at' })
    updatedAt: Date;
}
