import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    CreateDateColumn,
    UpdateDateColumn,
    Index,
} from 'typeorm';

@Entity('tutorials')
export class Tutorial {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column({ type: 'varchar', length: 255 })
    title: string;

    @Column({ type: 'text', nullable: true })
    description?: string;

    @Column({ name: 'video_url', type: 'varchar', length: 1000 })
    videoUrl: string;

    @Column({ name: 'youtube_video_id', type: 'varchar', length: 64, nullable: true })
    youtubeVideoId?: string;

    @Column({ name: 'thumbnail_url', type: 'varchar', length: 1000, nullable: true })
    thumbnailUrl?: string;

    @Index()
    @Column({ type: 'varchar', length: 100, default: 'General' })
    category: string;

    @Column({ type: 'text', nullable: true })
    tags?: string;

    @Index()
    @Column({ name: 'target_audience', type: 'varchar', length: 20, default: 'buyer' })
    targetAudience: string; // 'buyer', 'worker', 'all'

    @Index()
    @Column({ name: 'display_order', type: 'int', default: 0 })
    displayOrder: number;

    @Column({ type: 'varchar', length: 50, nullable: true, default: '2:30' })
    duration?: string;

    @Column({ name: 'views_count', type: 'int', default: 0 })
    viewsCount: number;

    @Index()
    @Column({ name: 'is_active', type: 'boolean', default: true })
    isActive: boolean;

    @CreateDateColumn({ name: 'created_at' })
    createdAt: Date;

    @UpdateDateColumn({ name: 'updated_at' })
    updatedAt: Date;
}
