import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { Task } from '../entities/task.entity';
import { TaskStatus } from '../../../task-engine/types/task-status.enum';

@Injectable()
export class TaskRepository {
    private static readonly statusAliases: Record<string, string[]> = {
        draft: ['draft'],
        active: ['active', 'draft', 'created', 'available'],
        pending: ['draft', 'active', 'created', 'available', 'pending'],
        assigned: ['assigned', 'accepted', 'in_progress', 'working', 'started'],
        accepted: ['accepted', 'assigned', 'in_progress'],
        in_progress: ['in_progress', 'accepted', 'assigned', 'working', 'started'],
        submitted: ['submitted', 'under_review', 'review'],
        under_review: ['under_review', 'submitted', 'review'],
        approved: ['approved', 'completed', 'done'],
        completed: ['completed', 'approved', 'done'],
        rejected: ['rejected'],
        cancelled: ['cancelled', 'canceled'],
        expired: ['expired'],
        failed: ['failed'],
    };

    constructor(
        @InjectRepository(Task)
        private readonly repository: Repository<Task>,
    ) { }

    async count(options?: any): Promise<number> {
        return this.repository.count(options);
    }

    private resolveStatuses(status: string): string[] {
        const normalizedStatus = (status || '').trim().toLowerCase();
        return TaskRepository.statusAliases[normalizedStatus] || [normalizedStatus];
    }

    matchesStatus(taskStatus: string, expectedStatus: string): boolean {
        if (!taskStatus || !expectedStatus) return false;
        const normTask = taskStatus.trim().toLowerCase();
        const normExpected = expectedStatus.trim().toLowerCase();
        if (normTask === normExpected) return true;

        const resolved = this.resolveStatuses(normExpected);
        return resolved.includes(normTask);
    }

    filterByStatus(tasks: Task[], expectedStatus: string): Task[] {
        return tasks.filter((task) => this.matchesStatus(task.status, expectedStatus));
    }

    async findById(id: string): Promise<Task | null> {
        return this.repository.findOne({ where: { id } });
    }

    async findByStatus(status: string): Promise<Task[]> {
        const statuses = this.resolveStatuses(status);
        const allVariations = Array.from(new Set([
            ...statuses,
            ...statuses.map(s => s.toLowerCase()),
            ...statuses.map(s => s.toUpperCase())
        ]));
        return this.repository.find({ where: { status: In(allVariations) } });
    }

    async findByWorker(workerId: string): Promise<Task[]> {
        return this.repository.find({ where: { assignedTo: workerId } });
    }

    async findAvailableForAssignment(): Promise<Task[]> {
        return this.repository.find({
            where: [
                { status: TaskStatus.ACTIVE, assignedTo: null },
                { status: 'active' as any, assignedTo: null },
                { status: TaskStatus.DRAFT, assignedTo: null },
                { status: 'draft' as any, assignedTo: null },
            ],
        });
    }

    async findByWorkerAndStatus(workerId: string, status: string): Promise<Task[]> {
        const statuses = this.resolveStatuses(status);
        const allVariations = Array.from(new Set([
            ...statuses,
            ...statuses.map(s => s.toLowerCase()),
            ...statuses.map(s => s.toUpperCase())
        ]));
        return this.repository.find({
            where: { assignedTo: workerId, status: In(allVariations) },
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
        const statuses = this.resolveStatuses(status);
        const allVariations = Array.from(new Set([
            ...statuses,
            ...statuses.map(s => s.toLowerCase()),
            ...statuses.map(s => s.toUpperCase())
        ]));
        return this.repository.count({ where: { status: In(allVariations) } });
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

    async getWorkerActiveTaskCounts(workerIds: string[]): Promise<Map<string, number>> {
        const counts = new Map<string, number>();
        if (!workerIds || workerIds.length === 0) return counts;

        const tasks = await this.repository.find({
            where: {
                assignedTo: In(workerIds),
                status: In(['assigned', 'accepted', 'in_progress', TaskStatus.ASSIGNED, TaskStatus.ACCEPTED, TaskStatus.IN_PROGRESS]),
            },
            select: ['assignedTo'],
        });

        for (const task of tasks) {
            if (task.assignedTo) {
                counts.set(task.assignedTo, (counts.get(task.assignedTo) || 0) + 1);
            }
        }
        return counts;
    }

    async getWorkerCampaignParticipationMap(
        workerIds: string[],
        campaignId?: string,
        orderId?: string,
    ): Promise<Map<string, boolean>> {
        const participationMap = new Map<string, boolean>();
        if (!workerIds || workerIds.length === 0 || (!campaignId && !orderId)) return participationMap;

        const whereConditions: any[] = [];
        if (campaignId) {
            whereConditions.push({ assignedTo: In(workerIds), campaignId });
        }
        if (orderId) {
            whereConditions.push({ assignedTo: In(workerIds), orderId });
        }

        const tasks = await this.repository.find({
            where: whereConditions,
            select: ['assignedTo', 'status'],
        });

        for (const task of tasks) {
            if (task.assignedTo && task.status !== 'cancelled' && task.status !== TaskStatus.CANCELLED) {
                participationMap.set(task.assignedTo, true);
            }
        }
        return participationMap;
    }
}
