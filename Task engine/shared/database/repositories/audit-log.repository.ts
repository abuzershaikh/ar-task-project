import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AuditLog } from '../entities/audit-log.entity';

export interface AuditLogFilterOptions {
    actorId?: string;
    entityType?: string;
    entityId?: string;
    action?: string;
    startDate?: Date;
    endDate?: Date;
    page?: number;
    limit?: number;
}

@Injectable()
export class AuditLogRepository {
    constructor(
        @InjectRepository(AuditLog)
        private readonly repository: Repository<AuditLog>,
    ) { }

    async create(data: Partial<AuditLog>): Promise<AuditLog> {
        const log = this.repository.create(data);
        return this.repository.save(log);
    }

    async findLogs(options: AuditLogFilterOptions): Promise<{ items: AuditLog[]; total: number }> {
        const query = this.repository.createQueryBuilder('log');

        if (options.actorId) {
            query.andWhere('log.actor_id = :actorId', { actorId: options.actorId });
        }

        if (options.entityType) {
            query.andWhere('log.entity_type = :entityType', { entityType: options.entityType });
        }

        if (options.entityId) {
            query.andWhere('log.entity_id = :entityId', { entityId: options.entityId });
        }

        if (options.action) {
            query.andWhere('log.action = :action', { action: options.action });
        }

        if (options.startDate) {
            query.andWhere('log.created_at >= :startDate', { startDate: options.startDate });
        }

        if (options.endDate) {
            query.andWhere('log.created_at <= :endDate', { endDate: options.endDate });
        }

        const page = options.page || 1;
        const limit = options.limit || 20;
        const skip = (page - 1) * limit;

        query.orderBy('log.created_at', 'DESC').skip(skip).take(limit);

        const [items, total] = await query.getManyAndCount();
        return { items, total };
    }

    async findById(id: string): Promise<AuditLog | null> {
        return this.repository.findOne({ where: { id } });
    }

    async findByAction(action: string): Promise<AuditLog[]> {
        return this.repository.find({ where: { action }, order: { createdAt: 'DESC' } });
    }

    async findRecent(limit = 100): Promise<AuditLog[]> {
        return this.repository.find({ order: { createdAt: 'DESC' }, take: limit });
    }

    async findByTarget(targetType: string, targetId: string): Promise<AuditLog[]> {
        return this.repository.find({
            where: { entityType: targetType, entityId: targetId },
            order: { createdAt: 'DESC' },
        });
    }
}
