import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { TaskGenerationJob, TaskGenerationJobStatus } from '../entities/task-generation-job.entity';

@Injectable()
export class TaskGenerationJobRepository {
    constructor(
        @InjectRepository(TaskGenerationJob)
        private readonly repository: Repository<TaskGenerationJob>,
    ) { }

    async findByOrderId(orderId: string): Promise<TaskGenerationJob | null> {
        return this.repository.findOne({ where: { orderId } });
    }

    async findPendingJobs(): Promise<TaskGenerationJob[]> {
        return this.repository.find({
            where: [
                { status: TaskGenerationJobStatus.PENDING },
                { status: TaskGenerationJobStatus.PROCESSING },
            ],
            order: { createdAt: 'ASC' },
        });
    }

    async create(data: Partial<TaskGenerationJob>): Promise<TaskGenerationJob> {
        const job = this.repository.create(data);
        return this.repository.save(job);
    }

    async updateProgress(
        id: string,
        generatedTasksCount: number,
        status?: TaskGenerationJobStatus,
        lastError?: string,
    ): Promise<TaskGenerationJob | null> {
        const payload: Partial<TaskGenerationJob> = { generatedTasksCount };
        if (status) payload.status = status;
        if (lastError !== undefined) payload.lastError = lastError;

        await this.repository.update(id, payload);
        return this.repository.findOne({ where: { id } });
    }
}
