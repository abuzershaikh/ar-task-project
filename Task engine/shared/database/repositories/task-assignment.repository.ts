import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';
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
    async findByWorker(workerId: string | string[]): Promise<TaskAssignment[]> {
        const ids = Array.isArray(workerId) ? workerId.filter(Boolean) : [workerId];
        if (ids.length === 0) return [];
        return this.repository.find({
            where: { workerId: In(ids) },
            order: { assignedAt: 'DESC' },
        });
    }

    async findByWorkerAndOrderUnit(workerId: string | string[], orderUnitId: string): Promise<TaskAssignment | null> {
        const ids = Array.isArray(workerId) ? workerId.filter(Boolean) : [workerId];
        if (ids.length === 0 || !orderUnitId) return null;
        return this.repository.findOne({
            where: { workerId: In(ids), orderUnitId },
        });
    }

    async findByWorkerAndTask(workerId: string | string[], taskId: string): Promise<TaskAssignment | null> {
        const ids = Array.isArray(workerId) ? workerId.filter(Boolean) : [workerId];
        if (ids.length === 0 || !taskId) return null;
        return this.repository.findOne({
            where: { workerId: In(ids), taskId },
        });
    }

    async findActiveAssignmentByUnit(orderUnitId: string): Promise<TaskAssignment | null> {
        if (!orderUnitId) return null;
        return this.repository.findOne({
            where: [
                { orderUnitId, status: TaskAssignmentStatus.ASSIGNED },
                { orderUnitId, status: TaskAssignmentStatus.ACCEPTED },
                { orderUnitId, status: TaskAssignmentStatus.STARTED },
                { orderUnitId, status: TaskAssignmentStatus.SUBMITTED },
            ],
            order: { attemptNumber: 'DESC' },
        });
    }

    async findCampaignIdsByWorker(workerId: string | string[]): Promise<string[]> {
        const ids = Array.isArray(workerId) ? workerId.filter(Boolean) : [workerId];
        if (ids.length === 0) return [];
        const records = await this.repository.find({
            where: { workerId: In(ids) },
            select: ['campaignId', 'orderId'],
        });
        const cIds: string[] = [];
        for (const r of records) {
            if (r.campaignId) cIds.push(r.campaignId);
            if (r.orderId) cIds.push(r.orderId);
        }
        return Array.from(new Set(cIds));
    }
}
