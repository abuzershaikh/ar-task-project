import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    CreateDateColumn,
    UpdateDateColumn,
} from 'typeorm';

@Entity('worker_scores')
export class WorkerScore {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column({ name: 'worker_id' })
    workerId: string;

    @Column({ name: 'total_score', type: 'decimal', precision: 5, scale: 2 })
    totalScore: number;

    @Column({ name: 'quality_score', type: 'decimal', precision: 5, scale: 2 })
    qualityScore: number;

    @Column({ name: 'completion_score', type: 'decimal', precision: 5, scale: 2 })
    completionScore: number;

    @Column({ name: 'reliability_score', type: 'decimal', precision: 5, scale: 2 })
    reliabilityScore: number;

    @Column({ name: 'rating_score', type: 'decimal', precision: 5, scale: 2 })
    ratingScore: number;

    @Column({ name: 'recent_performance_score', type: 'decimal', precision: 5, scale: 2 })
    recentPerformanceScore: number;

    @Column({ name: 'experience_score', type: 'decimal', precision: 5, scale: 2 })
    experienceScore: number;

    @Column({ type: 'json', nullable: true })
    breakdown: any;

    @CreateDateColumn({ name: 'created_at' })
    createdAt: Date;

    @UpdateDateColumn({ name: 'updated_at' })
    updatedAt: Date;
}
