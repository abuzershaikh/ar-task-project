import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    CreateDateColumn,
    UpdateDateColumn,
} from 'typeorm';

@Entity('task_submissions')
export class TaskSubmission {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column({ name: 'task_id' })
    taskId: string;

    @Column({ name: 'worker_id' })
    workerId: string;

    @Column({ type: 'json' })
    data: any;

    @Column({ type: 'json', nullable: true })
    proofs: any;

    @Column({ type: 'varchar', length: 50 })
    status: string;

    @Column({ name: 'review_status', type: 'varchar', length: 50, nullable: true })
    reviewStatus: string;

    @Column({ name: 'reviewed_by', nullable: true })
    reviewedBy: string;

    @Column({ name: 'reviewed_at', type: 'timestamp', nullable: true })
    reviewedAt: Date;

    @Column({ name: 'review_notes', type: 'text', nullable: true })
    reviewNotes: string;

    @CreateDateColumn({ name: 'created_at' })
    createdAt: Date;

    @UpdateDateColumn({ name: 'updated_at' })
    updatedAt: Date;
}
