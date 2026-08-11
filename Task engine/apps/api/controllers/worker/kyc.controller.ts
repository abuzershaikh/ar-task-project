import { Controller, Get, Post, Body, BadRequestException } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { KycRepository } from '../../../../shared/database/repositories/kyc.repository';
import { WorkerRepository } from '../../../../shared/database/repositories/worker.repository';
import { KycStatus, DocumentType } from '../../../../shared/database/entities/kyc.entity';
import { Roles } from '../../../../shared/auth/decorators/roles.decorator';
import { CurrentUser } from '../../../../shared/auth/decorators/current-user.decorator';
import { UserRole, User } from '../../../../shared/database/entities/user.entity';

@ApiTags('Worker - KYC')
@Roles(UserRole.WORKER)
@ApiBearerAuth('bearer')
@Controller('worker/kyc')
export class WorkerKycController {
    constructor(
        private readonly kycRepo: KycRepository,
        private readonly workerRepo: WorkerRepository,
    ) { }

    private async getWorker(userId: string) {
        let worker = await this.workerRepo.findByUserId(userId);
        if (!worker) {
            worker = await this.workerRepo.create({
                userId,
                status: 'active',
                kycStatus: 'pending',
            });
        }
        return worker;
    }

    @Get('status')
    @ApiOperation({ summary: 'Get worker KYC status and details' })
    async getStatus(@CurrentUser() user: User) {
        const worker = await this.getWorker(user.id);
        const kyc = await this.kycRepo.findByWorkerId(worker.id);

        return {
            success: true,
            kycStatus: kyc ? kyc.status : KycStatus.DRAFT,
            kyc: kyc || null,
        };
    }

    @Post()
    @ApiOperation({ summary: 'Submit or update worker KYC application' })
    async submitKyc(
        @CurrentUser() user: User,
        @Body()
        body: {
            fullName: string;
            dateOfBirth?: string;
            gender?: string;
            address?: string;
            city?: string;
            state?: string;
            pincode?: string;
            country?: string;
            documentType?: DocumentType;
            documentNumber?: string;
            documents?: any;
        },
    ) {
        const worker = await this.getWorker(user.id);
        let kyc = await this.kycRepo.findByWorkerId(worker.id);

        if (kyc && (kyc.status === KycStatus.VERIFIED || kyc.status === KycStatus.UNDER_REVIEW)) {
            throw new BadRequestException(`Cannot update KYC while status is ${kyc.status}`);
        }

        const payload = {
            workerId: worker.id,
            fullName: body.fullName || user.fullName,
            dateOfBirth: body.dateOfBirth ? new Date(body.dateOfBirth) : undefined,
            gender: body.gender,
            address: body.address,
            city: body.city,
            state: body.state,
            pincode: body.pincode,
            country: body.country,
            documentType: body.documentType,
            documentNumber: body.documentNumber,
            documents: body.documents || [],
            status: KycStatus.SUBMITTED,
            submittedAt: new Date(),
        };

        if (kyc) {
            kyc = await this.kycRepo.update(kyc.id, payload);
        } else {
            kyc = await this.kycRepo.create(payload);
        }

        await this.workerRepo.update(worker.id, { kycStatus: KycStatus.SUBMITTED });

        return {
            success: true,
            kyc,
            message: 'KYC application submitted successfully',
        };
    }
}
