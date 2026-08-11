import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
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
        workerId: string,
    ): Promise<CampaignWorkerParticipation | null> {
        return this.repository.findOne({
            where: { campaignId, workerId },
        });
    }

    async findUsedWorkerIdsByCampaign(campaignId: string): Promise<string[]> {
        const records = await this.repository.find({
            where: { campaignId },
            select: ['workerId'],
        });
        return records.map((r) => r.workerId);
    }

    async findCampaignIdsByWorker(workerId: string): Promise<string[]> {
        const records = await this.repository.find({
            where: { workerId },
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
