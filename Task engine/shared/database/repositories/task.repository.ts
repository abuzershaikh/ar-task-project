import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { Task } from '../entities/task.entity';
import { TaskStatus } from '../../../task-engine/types/task-status.enum';

@Injectable()
export class TaskRepository {
    private static readonly statusAliases: Record<string, TaskStatus[]> = {
        [TaskStatus.DRAFT]: [TaskStatus.DRAFT],
        [TaskStatus.ACTIVE]: [TaskStatus.ACTIVE],
        pending: [TaskStatus.DRAFT, TaskStatus.ACTIVE],
        [TaskStatus.ASSIGNED]: [TaskStatus.ASSIGNED],
        [TaskStatus.ACCEPTED]: [TaskStatus.ACCEPTED],
        [TaskStatus.IN_PROGRESS]: [TaskStatus.IN_PROGRESS],
        [TaskStatus.SUBMITTED]: [TaskStatus.SUBMITTED],
        [TaskStatus.UNDER_REVIEW]: [TaskStatus.UNDER_REVIEW],
        [TaskStatus.APPROVED]: [TaskStatus.APPROVED],
        completed: [TaskStatus.APPROVED],
        [TaskStatus.REJECTED]: [TaskStatus.REJECTED],
        [TaskStatus.CANCELLED]: [TaskStatus.CANCELLED],
        [TaskStatus.EXPIRED]: [TaskStatus.EXPIRED],
        [TaskStatus.FAILED]: [TaskStatus.FAILED],
    };

    constructor(
        @InjectRepository(Task)
        private readonly repository: Repository<Task>,
    ) { }

    async count(options?: any): Promise<number> {
        return this.repository.count(options);
    }

    private resolveStatuses(status: string): TaskStatus[] {
        const normalizedStatus = status.trim().toLowerCase();
        return TaskRepository.statusAliases[normalizedStatus] || [normalizedStatus as TaskStatus];
    }

    matchesStatus(taskStatus: string, expectedStatus: string): boolean {
        return this.resolveStatuses(expectedStatus).includes(taskStatus as TaskStatus);
    }

    filterByStatus(tasks: Task[], expectedStatus: string): Task[] {
        return tasks.filter((task) => this.matchesStatus(task.status, expectedStatus));
    }

    async findById(id: string): Promise<Task | null> {
        return this.repository.findOne({ where: { id } });
    }

    async findByStatus(status: string): Promise<Task[]> {
        return this.repository.find({ where: { status: In(this.resolveStatuses(status)) } });
    }

    async findByWorker(workerId: string): Promise<Task[]> {
        return this.repository.find({ where: { assignedTo: workerId } });
    }

    async findAvailableForAssignment(): Promise<Task[]> {
        return this.repository.find({
            where: { status: TaskStatus.ACTIVE, assignedTo: null },
        });
    }

    async findByWorkerAndStatus(workerId: string, status: string): Promise<Task[]> {
        return this.repository.find({
            where: { assignedTo: workerId, status: In(this.resolveStatuses(status)) },
        });
    }

    async create(data: Partial<Task>): Promise<Task> {
        const task = this.repository.create(data);
        return this.repository.save(task);
    }

    async update(id: string, data: Partial<Task>): Promise<Task> {
        await this.repository.update(id, data);
        return this.findById(id);
    }

    async delete(id: string): Promise<void> {
        await this.repository.delete(id);
    }

    async countByStatus(status: string): Promise<number> {
        return this.repository.count({ where: { status: In(this.resolveStatuses(status)) } });
    }

    async findByOrderId(orderId: string): Promise<Task[]> {
        return this.repository.find({ where: { orderId } });
    }

    async findAssignedTasks(): Promise<Task[]> {
        return this.repository.find({
            where: [
                { status: TaskStatus.ASSIGNED },
                { status: TaskStatus.ACCEPTED },
                { status: TaskStatus.IN_PROGRESS },
            ],
        });
    }
}
