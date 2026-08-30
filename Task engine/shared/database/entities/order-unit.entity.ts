import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    CreateDateColumn,
    UpdateDateColumn,
    Index,
} from 'typeorm';

@Entity('order_units')
export class OrderUnit {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Index()
    @Column({ name: 'order_id' })
    orderId: string;

    @Column({ name: 'unit_number', type: 'int' })
    unitNumber: number;

    @Column({ name: 'target_url', length: 500, nullable: true })
    targetUrl: string;

    @Column({ name: 'generated_content', type: 'text', nullable: true })
    generatedContent: string;

    @Column({ length: 50, default: 'PENDING' })
    status: string;

    @CreateDateColumn({ name: 'created_at' })
    createdAt: Date;

    @UpdateDateColumn({ name: 'updated_at' })
    updatedAt: Date;
}
