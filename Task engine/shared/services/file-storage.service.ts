import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import * as fs from 'fs';
import * as path from 'path';
import { v4 as uuidv4 } from 'uuid';
import { FileRepository } from '../database/repositories/file.repository';
import { File, FileType } from '../database/entities/file.entity';

export interface UploadFileOptions {
    uploadedBy: string;
    type: FileType;
    originalName: string;
    mimeType: string;
    buffer: Buffer;
    entityType?: string;
    entityId?: string;
    metadata?: any;
}

@Injectable()
export class FileStorageService {
    private readonly uploadDir = path.join(process.cwd(), 'uploads');

    constructor(private readonly fileRepo: FileRepository) {
        if (!fs.existsSync(this.uploadDir)) {
            fs.mkdirSync(this.uploadDir, { recursive: true });
        }
    }

    async saveFile(options: UploadFileOptions): Promise<File> {
        if (!options.buffer || options.buffer.length === 0) {
            throw new BadRequestException('File content cannot be empty');
        }

        const ext = path.extname(options.originalName) || '';
        const fileName = `${uuidv4()}${ext}`;
        const filePath = path.join(this.uploadDir, fileName);

        await fs.promises.writeFile(filePath, options.buffer);

        return this.fileRepo.create({
            uploadedBy: options.uploadedBy,
            type: options.type,
            originalName: options.originalName,
            fileName,
            filePath: `uploads/${fileName}`,
            mimeType: options.mimeType,
            fileSize: options.buffer.length,
            entityType: options.entityType,
            entityId: options.entityId,
            metadata: options.metadata,
        });
    }

    async getFileRecord(fileId: string): Promise<File> {
        const record = await this.fileRepo.findById(fileId);
        if (!record) {
            throw new NotFoundException('File not found');
        }
        return record;
    }

    getAbsoluteFilePath(relativeOrFileName: string): string {
        const basename = path.basename(relativeOrFileName);
        return path.join(this.uploadDir, basename);
    }

    async getFileStream(fileId: string): Promise<{ stream: fs.ReadStream; file: File }> {
        const file = await this.getFileRecord(fileId);
        const fullPath = this.getAbsoluteFilePath(file.fileName);

        if (!fs.existsSync(fullPath)) {
            throw new NotFoundException('Physical file missing on server');
        }

        const stream = fs.createReadStream(fullPath);
        return { stream, file };
    }
}
