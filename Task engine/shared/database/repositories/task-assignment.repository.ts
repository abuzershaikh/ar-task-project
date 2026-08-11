import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { TaskAssignment, TaskAssignmentStatus } from '../entities/task-assignment.entity';

@Injectable()
export class TaskAssignmentRepository {
    constructor(
        @InjectRepository(TaskAssignment)
        private readonly repository: Repository<TaskAssignment>,
    ) { }

    async findByTaskId(taskId: string): Promise<TaskAssignment[]> {
        return this.repository.find({
            where: { taskId },
            order: { attemptNumber: 'ASC' },
        });
    }

    async findActiveAssignment(taskId: string): Promise<TaskAssignment | null> {
        return this.repository.findOne({
            where: [
                { taskId, status: TaskAssignmentStatus.ASSIGNED },
                { taskId, status: TaskAssignmentStatus.ACCEPTED },
                { taskId, status: TaskAssignmentStatus.STARTED },
                { taskId, status: TaskAssignmentStatus.SUBMITTED },
            ],
            order: { attemptNumber: 'DESC' },
        });
    }

    async createAssignment(data: Partial<TaskAssignment>): Promise<TaskAssignment> {
        const attempts = await this.findByTaskId(data.taskId!);
        const attemptNumber = attempts.length + 1;

        const assignment = this.repository.create({
            ...data,
            attemptNumber,
            status: TaskAssignmentStatus.ASSIGNED,
            assignedAt: new Date(),
        });

        return this.repository.save(assignment);
    }

    async updateStatus(
        id: string,
        status: TaskAssignmentStatus,
        timestamps?: {
            acceptedAt?: Date;
            startedAt?: Date;
            submittedAt?: Date;
            expiredAt?: Date;
            completedAt?: Date;
            releaseReason?: string;
        },
    ): Promise<TaskAssignment | null> {
        const payload: Partial<TaskAssignment> = { status, ...timestamps };
        await this.repository.update(id, payload);
        return this.repository.findOne({ where: { id } });
    }
}
