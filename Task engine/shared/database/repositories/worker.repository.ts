import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Worker } from '../entities/worker.entity';

@Injectable()
export class WorkerRepository {
    constructor(
        @InjectRepository(Worker)
        private readonly repository: Repository<Worker>,
    ) { }

    async findById(id: string): Promise<Worker | null> {
        return this.repository.findOne({ where: { id } });
    }

    async findByUserId(userId: string): Promise<Worker | null> {
        return this.repository.findOne({ where: { userId } });
    }

    async findActiveWorkers(): Promise<Worker[]> {
        return this.repository.find({
            where: {
                status: 'active',
                kycStatus: 'approved'
            }
        });
    }

    async findByIds(ids: string[]): Promise<Worker[]> {
        return this.repository.findByIds(ids);
    }

    async create(data: Partial<Worker>): Promise<Worker> {
        const worker = this.repository.create(data);
        return this.repository.save(worker);
    }

    async update(id: string, data: Partial<Worker>): Promise<Worker> {
        await this.repository.update(id, data);
        return this.findById(id);
    }

    async updateStats(id: string, stats: any): Promise<void> {
        await this.repository.update(id, stats);
    }
}
