import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    CreateDateColumn,
    Index,
} from 'typeorm';

export enum FileType {
    IMAGE = 'IMAGE',
    VIDEO = 'VIDEO',
    DOCUMENT = 'DOCUMENT',
    PROOF = 'PROOF',
    KYC_DOCUMENT = 'KYC_DOCUMENT',
}

@Entity('files')
@Index(['uploadedBy'])
@Index(['entityType', 'entityId'])
export class File {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column({ name: 'uploaded_by' })
    uploadedBy: string;

    @Column({ type: 'enum', enum: FileType })
    type: FileType;

    @Column({ name: 'original_name' })
    originalName: string;

    @Column({ name: 'file_name' })
    fileName: string;

    @Column({ name: 'file_path' })
    filePath: string;

    @Column({ name: 'mime_type' })
    mimeType: string;

    @Column({ name: 'file_size', type: 'bigint' })
    fileSize: number;

    @Column({ name: 'entity_type', nullable: true })
    entityType: string;

    @Column({ name: 'entity_id', nullable: true })
    entityId: string;

    @Column({ type: 'json', nullable: true })
    metadata: any;

    @CreateDateColumn({ name: 'created_at' })
    createdAt: Date;
}
