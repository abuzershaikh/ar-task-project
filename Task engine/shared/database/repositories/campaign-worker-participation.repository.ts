import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';
import { CampaignWorkerParticipation, ParticipationStatus } from '../entities/campaign-worker-participation.entity';

@Injectable()
export class CampaignWorkerParticipationRepository {
    private readonly logger = new Logger(CampaignWorkerParticipationRepository.name);

    constructor(
        @InjectRepository(CampaignWorkerParticipation)
        private readonly repository: Repository<CampaignWorkerParticipation>,
    ) { }

    async findByCampaignAndWorker(
        campaignId: string,
        workerId: string | string[],
    ): Promise<CampaignWorkerParticipation | null> {
        const ids = Array.isArray(workerId) ? workerId.filter(Boolean) : [workerId];
        if (ids.length === 0) return null;
        return this.repository.findOne({
            where: { campaignId, workerId: In(ids) },
        });
    }

    async findUsedWorkerIdsByCampaign(campaignId: string): Promise<string[]> {
        const records = await this.repository.find({
            where: { campaignId },
            select: ['workerId'],
        });
        const rawIds = records.map((r) => r.workerId).filter(Boolean);
        if (rawIds.length === 0) return [];

        const allAliases = new Set<string>();
        for (const id of rawIds) {
            allAliases.add(id.toLowerCase().trim());
        }

        try {
            const rows = await this.repository.query(
                `SELECT u.id AS userId, u.email AS userEmail, w.id AS workerId
                 FROM users u
                 LEFT JOIN workers w ON w.user_id = u.id
                 WHERE u.id IN (?) OR u.email IN (?) OR w.id IN (?)`,
                [rawIds, rawIds, rawIds],
            );
            for (const r of rows) {
                if (r.userId) allAliases.add(r.userId.toString().trim().toLowerCase());
                if (r.userEmail) allAliases.add(r.userEmail.toString().trim().toLowerCase());
                if (r.workerId) allAliases.add(r.workerId.toString().trim().toLowerCase());
            }
        } catch (err) {
            this.logger.error(`Error resolving aliases for used campaign workers: ${err?.message}`);
            throw err;
        }

        return Array.from(allAliases);
    }

    async findCampaignIdsByWorker(workerId: string | string[]): Promise<string[]> {
        const ids = Array.isArray(workerId) ? workerId.filter(Boolean) : [workerId];
        if (ids.length === 0) return [];
        const records = await this.repository.find({
            where: { workerId: In(ids) },
            select: ['campaignId'],
        });

        return records.map((record) => record.campaignId);
    }

    async recordParticipation(
        campaignId: string,
        workerId: string,
        status: ParticipationStatus = ParticipationStatus.ASSIGNED,
    ): Promise<CampaignWorkerParticipation> {
        const existing = await this.findByCampaignAndWorker(campaignId, workerId);
        if (existing) {
            this.logger.warn(`Worker '${workerId}' has ALREADY participated in Campaign '${campaignId}'. Updating status.`);
            existing.status = status;
            existing.lastAssignedAt = new Date();
            if (status === ParticipationStatus.COMPLETED) existing.completedCount += 1;
            if (status === ParticipationStatus.EXPIRED) existing.expiredCount += 1;
            if (status === ParticipationStatus.REJECTED) existing.rejectedCount += 1;
            return this.repository.save(existing);
        }

        const participation = this.repository.create({
            campaignId,
            workerId,
            status,
            assignedCount: 1,
            completedCount: status === ParticipationStatus.COMPLETED ? 1 : 0,
            expiredCount: status === ParticipationStatus.EXPIRED ? 1 : 0,
            rejectedCount: status === ParticipationStatus.REJECTED ? 1 : 0,
            firstAssignedAt: new Date(),
            lastAssignedAt: new Date(),
        });

        return this.repository.save(participation);
    }

    async updateStatus(
        campaignId: string,
        workerId: string,
        status: ParticipationStatus,
    ): Promise<CampaignWorkerParticipation | null> {
        const existing = await this.findByCampaignAndWorker(campaignId, workerId);
        if (!existing) {
            return this.recordParticipation(campaignId, workerId, status);
        }

        existing.status = status;
        existing.lastAssignedAt = new Date();
        if (status === ParticipationStatus.COMPLETED) existing.completedCount += 1;
        if (status === ParticipationStatus.EXPIRED) existing.expiredCount += 1;
        if (status === ParticipationStatus.REJECTED) existing.rejectedCount += 1;

        return this.repository.save(existing);
    }

    async getCampaignParticipationSummary(campaignId: string) {
        const list = await this.repository.find({ where: { campaignId } });
        return {
            totalUniqueWorkersParticipated: list.length,
            completed: list.filter((p) => p.status === ParticipationStatus.COMPLETED).length,
            expired: list.filter((p) => p.status === ParticipationStatus.EXPIRED).length,
            rejected: list.filter((p) => p.status === ParticipationStatus.REJECTED).length,
            activeAssigned: list.filter((p) => p.status === ParticipationStatus.ASSIGNED).length,
        };
    }
}
