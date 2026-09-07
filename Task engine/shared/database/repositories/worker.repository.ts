import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, MoreThan } from 'typeorm';
import { Worker } from '../entities/worker.entity';

// Activity status constants
export const ACTIVITY_THRESHOLD_ACTIVE_HOURS = 24;
export const ACTIVITY_THRESHOLD_INACTIVE_HOURS = 48;

export type WorkerActivityStatus = 'ACTIVE' | 'WARNING' | 'INACTIVE';

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

    /**
     * Find workers who are active AND eligible (lastActiveAt < 48 hours)
     * Used by matching engine for task distribution
     */
    async findActiveAndEligibleWorkers(): Promise<Worker[]> {
        const cutoff48h = new Date(Date.now() - ACTIVITY_THRESHOLD_INACTIVE_HOURS * 60 * 60 * 1000);

        return this.repository
            .createQueryBuilder('w')
            .where('w.status = :status', { status: 'active' })
            .andWhere('w.kycStatus = :kycStatus', { kycStatus: 'approved' })
            .andWhere('(w.lastActiveAt IS NOT NULL AND w.lastActiveAt > :cutoff)', { cutoff: cutoff48h })
            .andWhere('(w.taskCooldownUntil IS NULL OR w.taskCooldownUntil <= :now)', { now: new Date() })
            .getMany();
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

    async findWorker(idOrUserId: string): Promise<Worker | null> {
        if (!idOrUserId) return null;
        return this.repository.findOne({
            where: [{ id: idOrUserId }, { userId: idOrUserId }],
        });
    }

    async incrementTasksCompleted(idOrUserId: string): Promise<void> {
        const worker = await this.findWorker(idOrUserId);
        if (worker) {
            await this.repository.increment({ id: worker.id }, 'totalTasksCompleted', 1);
            // Auto-update lastActiveAt on task completion
            await this.updateLastActiveAt(worker.id);
        }
    }

    async decrementTasksCompleted(idOrUserId: string): Promise<void> {
        const worker = await this.findWorker(idOrUserId);
        if (worker && Number(worker.totalTasksCompleted || 0) > 0) {
            await this.repository.decrement({ id: worker.id }, 'totalTasksCompleted', 1);
        }
    }

    async incrementTasksRejected(idOrUserId: string): Promise<void> {
        const worker = await this.findWorker(idOrUserId);
        if (worker) {
            await this.repository.increment({ id: worker.id }, 'totalTasksRejected', 1);
        }
    }

    // ─── Activity Tracking Methods ───────────────────────────────────────

    /**
     * Update worker's lastActiveAt to NOW
     * Called on heartbeat, task completion, app open, etc.
     */
    async updateLastActiveAt(idOrUserId: string): Promise<void> {
        const worker = await this.findWorker(idOrUserId);
        if (worker) {
            await this.repository.update(worker.id, {
                lastActiveAt: new Date(),
            });
        }
    }

    /**
     * Get worker's activity status based on lastActiveAt
     * < 24h = ACTIVE, 24-48h = WARNING, >= 48h = INACTIVE
     */
    getActivityStatus(worker: Worker): WorkerActivityStatus {
        if (!worker.lastActiveAt) {
            return 'INACTIVE';
        }

        const hoursSinceActive = (Date.now() - new Date(worker.lastActiveAt).getTime()) / (1000 * 60 * 60);

        if (hoursSinceActive < ACTIVITY_THRESHOLD_ACTIVE_HOURS) {
            return 'ACTIVE';
        } else if (hoursSinceActive < ACTIVITY_THRESHOLD_INACTIVE_HOURS) {
            return 'WARNING';
        } else {
            return 'INACTIVE';
        }
    }

    /**
     * Check if worker is eligible based on activity (hard gate)
     * active < 48h → eligible
     * inactive >= 48h → NOT eligible
     */
    isActivityEligible(worker: Worker): boolean {
        if (!worker.lastActiveAt) return false;
        const hoursSinceActive = (Date.now() - new Date(worker.lastActiveAt).getTime()) / (1000 * 60 * 60);
        return hoursSinceActive < ACTIVITY_THRESHOLD_INACTIVE_HOURS;
    }

    // ─── Performance Points Methods ──────────────────────────────────────

    /**
     * Apply performance point change
     * +1 for completion, -3 for rejection, -5 for expiry
     */
    async applyPerformancePointChange(idOrUserId: string, points: number): Promise<number> {
        const worker = await this.findWorker(idOrUserId);
        if (!worker) return 0;

        const currentPoints = Number(worker.performancePoints || 0);
        const newPoints = currentPoints + points;

        await this.repository.update(worker.id, {
            performancePoints: newPoints,
        });

        return newPoints;
    }

    /**
     * Get consecutive rejection count for cooldown escalation
     * Counts recent consecutive rejected tasks
     */
    async getConsecutiveRejectionCount(workerId: string): Promise<number> {
        const worker = await this.findWorker(workerId);
        if (!worker) return 0;

        // Use performancePoints as a proxy: every -3 is a rejection
        // For more accurate tracking, we check totalTasksRejected
        const rejected = Number(worker.totalTasksRejected || 0);
        const completed = Number(worker.totalTasksCompleted || 0);

        // Simple heuristic: if recent rejections outpace completions
        if (rejected === 0) return 0;
        if (completed === 0) return rejected;

        // Return recent rejection streak based on performance points being negative
        const points = Number(worker.performancePoints || 0);
        if (points >= 0) return 0;

        // Estimate consecutive rejections from negative points
        return Math.min(Math.floor(Math.abs(points) / 3), rejected);
    }

    // ─── Cooldown Methods ────────────────────────────────────────────────

    /**
     * Set task cooldown for worker (rejection penalty escalation)
     * 1st: 30 min, 2nd: 2h, 3rd: 6h, 4th+: 24h
     */
    async setTaskCooldown(idOrUserId: string, consecutiveRejections: number): Promise<Date | null> {
        const worker = await this.findWorker(idOrUserId);
        if (!worker) return null;

        let cooldownMinutes: number;
        switch (consecutiveRejections) {
            case 1: cooldownMinutes = 30; break;
            case 2: cooldownMinutes = 120; break;   // 2 hours
            case 3: cooldownMinutes = 360; break;    // 6 hours
            default: cooldownMinutes = 1440; break;  // 24 hours
        }

        const cooldownUntil = new Date(Date.now() + cooldownMinutes * 60 * 1000);

        await this.repository.update(worker.id, {
            taskCooldownUntil: cooldownUntil,
        });

        return cooldownUntil;
    }

    /**
     * Check if worker is currently on task cooldown
     */
    isOnCooldown(worker: Worker): boolean {
        if (!worker.taskCooldownUntil) return false;
        return new Date(worker.taskCooldownUntil).getTime() > Date.now();
    }

    /**
     * Clear task cooldown (when worker becomes active again or cooldown expires)
     */
    async clearCooldown(idOrUserId: string): Promise<void> {
        const worker = await this.findWorker(idOrUserId);
        if (worker) {
            await this.repository.update(worker.id, {
                taskCooldownUntil: null,
            });
        }
    }
}
