import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    CreateDateColumn,
    Index,
} from 'typeorm';

@Entity('audit_logs')
@Index(['actorId'])
@Index(['entityType', 'entityId'])
@Index(['action'])
@Index(['createdAt'])
export class AuditLog {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column({ name: 'actor_id' })
    actorId: string;

    @Column({ name: 'actor_role' })
    actorRole: string;

    @Column()
    action: string;

    @Column({ name: 'entity_type' })
    entityType: string;

    @Column({ name: 'entity_id' })
    entityId: string;

    @Column({ name: 'previous_state', type: 'json', nullable: true })
    previousState: any;

    @Column({ name: 'new_state', type: 'json', nullable: true })
    newState: any;

    @Column({ type: 'json', nullable: true })
    metadata: any;

    @Column({ nullable: true })
    ip: string;

    @Column({ name: 'user_agent', type: 'text', nullable: true })
    userAgent: string;

    @Column({ name: 'request_id', nullable: true })
    requestId: string;

    @CreateDateColumn({ name: 'created_at' })
    createdAt: Date;
}
