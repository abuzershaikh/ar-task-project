import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { Task } from '../entities/task.entity';
import { Worker } from '../entities/worker.entity';
import { TaskStatus } from '../../../task-engine/types/task-status.enum';

@Injectable()
export class TaskRepository {
    private static readonly statusAliases: Record<string, string[]> = {
        draft: ['draft'],
        active: ['active', 'created', 'available'],
        pending: ['active', 'created', 'available', 'pending'],
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
        return this.repository.find({
            where: { status: In(allVariations) },
            order: { createdAt: 'DESC' },
        });
    }

    async findByWorker(workerId: string): Promise<Task[]> {
        return this.repository.find({
            where: { assignedTo: workerId },
            order: { createdAt: 'DESC' },
        });
    }

    async findAvailableForAssignment(): Promise<Task[]> {
        return this.repository
            .createQueryBuilder('task')
            .leftJoin('orders', 'order', 'order.id = task.order_id')
            .where('task.status IN (:...statuses)', { statuses: [TaskStatus.ACTIVE, 'active'] })
            .andWhere('(task.assigned_to IS NULL OR task.assigned_to = :empty)', { empty: '' })
            .andWhere('(order.id IS NULL OR order.status IN (:...orderStatuses))', {
                orderStatuses: ['ACTIVE', 'active', 'IN_PROGRESS', 'in_progress'],
            })
            .orderBy('task.created_at', 'DESC')
            .getMany();
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
            order: { createdAt: 'DESC' },
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
        return this.repository.find({
            where: { orderId },
            order: { createdAt: 'DESC' },
        });
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

        // Resolve dual IDs: workers.id <-> workers.userId
        let allSearchIds = [...workerIds];
        const idToRelatedIds = new Map<string, string[]>();

        try {
            const workers = await this.repository.manager.find(Worker, {
                where: [
                    { id: In(workerIds) },
                    { userId: In(workerIds) },
                ],
                select: ['id', 'userId'],
            });

            for (const w of workers) {
                const pair = [w.id, w.userId].filter(Boolean);
                idToRelatedIds.set(w.id, pair);
                idToRelatedIds.set(w.userId, pair);
                allSearchIds.push(w.id, w.userId);
            }
        } catch (_) {}

        allSearchIds = Array.from(new Set(allSearchIds));

        const tasks = await this.repository.find({
            where: {
                assignedTo: In(allSearchIds),
                status: In(['assigned', 'accepted', 'in_progress', TaskStatus.ASSIGNED, TaskStatus.ACCEPTED, TaskStatus.IN_PROGRESS]),
            },
            select: ['assignedTo'],
        });

        for (const task of tasks) {
            if (task.assignedTo) {
                const targetIds = idToRelatedIds.get(task.assignedTo) || [task.assignedTo];
                for (const tid of targetIds) {
                    counts.set(tid, (counts.get(tid) || 0) + 1);
                }
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

        // Resolve dual IDs: workers.id <-> workers.userId
        let allSearchIds = [...workerIds];
        const idToRelatedIds = new Map<string, string[]>();

        try {
            const workers = await this.repository.manager.find(Worker, {
                where: [
                    { id: In(workerIds) },
                    { userId: In(workerIds) },
                ],
                select: ['id', 'userId'],
            });

            for (const w of workers) {
                const pair = [w.id, w.userId].filter(Boolean);
                idToRelatedIds.set(w.id, pair);
                idToRelatedIds.set(w.userId, pair);
                allSearchIds.push(w.id, w.userId);
            }
        } catch (_) {}

        allSearchIds = Array.from(new Set(allSearchIds));

        const whereConditions: any[] = [];
        if (campaignId) {
            whereConditions.push({ assignedTo: In(allSearchIds), campaignId });
        }
        if (orderId) {
            whereConditions.push({ assignedTo: In(allSearchIds), orderId });
        }

        const tasks = await this.repository.find({
            where: whereConditions,
            select: ['assignedTo', 'status'],
        });

        for (const task of tasks) {
            if (task.assignedTo && task.status !== 'cancelled' && task.status !== TaskStatus.CANCELLED) {
                const targetIds = idToRelatedIds.get(task.assignedTo) || [task.assignedTo];
                for (const tid of targetIds) {
                    participationMap.set(tid, true);
                }
            }
        }
        return participationMap;
    }
}
