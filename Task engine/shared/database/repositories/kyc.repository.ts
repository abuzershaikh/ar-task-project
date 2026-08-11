import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { KycProfile, KycStatus } from '../entities/kyc.entity';

@Injectable()
export class KycRepository {
    constructor(
        @InjectRepository(KycProfile)
        private readonly repository: Repository<KycProfile>,
    ) { }

    async findById(id: string): Promise<KycProfile | null> {
        return this.repository.findOne({ where: { id } });
    }

    async findByWorkerId(workerId: string): Promise<KycProfile | null> {
        return this.repository.findOne({ where: { workerId } });
    }

    async findPending(): Promise<KycProfile[]> {
        return this.repository.find({
            where: [
                { status: KycStatus.SUBMITTED },
                { status: KycStatus.UNDER_REVIEW },
            ],
            order: { createdAt: 'ASC' },
        });
    }

    async create(data: Partial<KycProfile>): Promise<KycProfile> {
        const kyc = this.repository.create(data);
        return this.repository.save(kyc);
    }

    async update(id: string, data: Partial<KycProfile>): Promise<KycProfile> {
        await this.repository.update(id, data);
        return this.findById(id);
    }
}
