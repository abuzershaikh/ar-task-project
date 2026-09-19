import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    CreateDateColumn,
    Index,
} from 'typeorm';

@Entity('worker_completed_identities')
@Index(['workerKey', 'entityKey'], { unique: true })
export class WorkerCompletedIdentity {
    @PrimaryGeneratedColumn()
    id: number;

    @Column({ name: 'worker_key', length: 191 })
    workerKey: string;

    @Column({ name: 'entity_key', length: 191 })
    entityKey: string;

    @Column({ name: 'task_id', length: 64, nullable: true })
    taskId: string;

    @CreateDateColumn({ name: 'created_at' })
    createdAt: Date;
}
