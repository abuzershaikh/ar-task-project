import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    CreateDateColumn,
} from 'typeorm';

@Entity('earnings')
export class Earning {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column({ name: 'worker_id' })
    workerId: string;

    @Column({ name: 'task_id' })
    taskId: string;

    @Column({ type: 'decimal', precision: 10, scale: 2 })
    amount: number;

    @Column({ type: 'varchar', length: 50 })
    type: string;

    @Column({ type: 'varchar', length: 50 })
    status: string;

    @Column({ type: 'json', nullable: true })
    metadata: any;

    @Column({ name: 'ledger_entry_id', nullable: true })
    ledgerEntryId: string;

    @CreateDateColumn({ name: 'created_at' })
    createdAt: Date;
}
