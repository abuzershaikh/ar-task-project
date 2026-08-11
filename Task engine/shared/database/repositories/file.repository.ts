import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { File } from '../entities/file.entity';

@Injectable()
export class FileRepository {
    constructor(
        @InjectRepository(File)
        private readonly repository: Repository<File>,
    ) { }

    async findById(id: string): Promise<File | null> {
        return this.repository.findOne({ where: { id } });
    }

    async findByUploadedBy(uploadedBy: string): Promise<File[]> {
        return this.repository.find({
            where: { uploadedBy },
            order: { createdAt: 'DESC' },
        });
    }

    async findByEntity(entityType: string, entityId: string): Promise<File[]> {
        return this.repository.find({
            where: { entityType, entityId },
            order: { createdAt: 'DESC' },
        });
    }

    async create(data: Partial<File>): Promise<File> {
        const file = this.repository.create(data);
        return this.repository.save(file);
    }

    async delete(id: string): Promise<boolean> {
        const result = await this.repository.delete(id);
        return (result.affected || 0) > 0;
    }
}
