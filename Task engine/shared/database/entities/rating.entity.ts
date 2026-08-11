import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    CreateDateColumn,
    UpdateDateColumn,
    Index,
} from 'typeorm';

@Entity('ratings')
@Index(['taskId'], { unique: true })
@Index(['workerId'])
@Index(['buyerId'])
export class Rating {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column({ name: 'task_id' })
    taskId: string;

    @Column({ name: 'worker_id' })
    workerId: string;

    @Column({ name: 'buyer_id' })
    buyerId: string;

    @Column({ type: 'int' })
    rating: number; // 1-5

    @Column({ type: 'text', nullable: true })
    feedback: string;

    @Column({ type: 'json', nullable: true })
    categories: any; // quality, speed, communication, etc.

    @CreateDateColumn({ name: 'created_at' })
    createdAt: Date;

    @UpdateDateColumn({ name: 'updated_at' })
    updatedAt: Date;
}
