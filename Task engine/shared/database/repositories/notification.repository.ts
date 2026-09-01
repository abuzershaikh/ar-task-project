import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Notification } from '../entities/notification.entity';

@Injectable()
export class NotificationRepository {
    constructor(
        @InjectRepository(Notification)
        private readonly repository: Repository<Notification>,
    ) { }

    async findById(id: string): Promise<Notification | null> {
        return this.repository.findOne({ where: { id } });
    }

    async findByUserId(userId: string, limit = 50): Promise<Notification[]> {
        return this.repository.find({
            where: [
                { userId },
                { userId: 'ALL_WORKERS' },
                { userId: 'GLOBAL' },
            ],
            order: { createdAt: 'DESC' },
            take: limit,
        });
    }

    async countUnread(userId: string): Promise<number> {
        return this.repository.count({
            where: [
                { userId, isRead: false },
                { userId: 'ALL_WORKERS', isRead: false },
                { userId: 'GLOBAL', isRead: false },
            ],
        });
    }

    async markAsRead(id: string): Promise<void> {
        await this.repository.update(id, {
            isRead: true,
            readAt: new Date(),
        });
    }

    async markAllAsRead(userId: string): Promise<void> {
        await this.repository.update(
            { userId, isRead: false },
            { isRead: true, readAt: new Date() },
        );
    }

    async delete(id: string): Promise<void> {
        await this.repository.delete(id);
    }

    async deleteAllForUser(userId: string): Promise<void> {
        await this.repository
            .createQueryBuilder()
            .delete()
            .from(Notification)
            .where('user_id = :userId OR user_id = :allWorkers OR user_id = :global', {
                userId,
                allWorkers: 'ALL_WORKERS',
                global: 'GLOBAL',
            })
            .execute();
    }

    async create(data: Partial<Notification>): Promise<Notification> {
        const notification = this.repository.create(data);
        return this.repository.save(notification);
    }
}
