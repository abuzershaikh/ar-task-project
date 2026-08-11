import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { TaskSubmission } from '../entities/submission.entity';

@Injectable()
export class SubmissionRepository {
    constructor(
        @InjectRepository(TaskSubmission)
        private readonly repository: Repository<TaskSubmission>,
    ) { }

    async findById(id: string): Promise<TaskSubmission | null> {
        return this.repository.findOne({ where: { id } });
    }

    async findByTaskId(taskId: string): Promise<TaskSubmission | null> {
        return this.repository.findOne({ where: { taskId } });
    }

    async findPendingReviews(): Promise<TaskSubmission[]> {
        return this.repository.find({
            where: { reviewStatus: 'pending' },
        });
    }

    async findByWorker(workerId: string): Promise<TaskSubmission[]> {
        return this.repository.find({ where: { workerId } });
    }

    async create(data: Partial<TaskSubmission>): Promise<TaskSubmission> {
        const submission = this.repository.create(data);
        return this.repository.save(submission);
    }

    async update(id: string, data: Partial<TaskSubmission>): Promise<TaskSubmission> {
        await this.repository.update(id, data);
        return this.findById(id);
    }
}
